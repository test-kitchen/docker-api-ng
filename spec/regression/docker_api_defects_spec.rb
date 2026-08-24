# frozen_string_literal: true

require "spec_helper"

# Defects inherited from the docker-api gem, each documented in kitchen-dokken's
# own source as a workaround it had to carry. These are the acceptance criteria
# for the migration: every one of them is a named test here.
describe "defects designed out of docker-api" do
  # docker-api's Container.create forwards only `name` to the query string, so
  # `platform` is silently discarded. kitchen-dokken works around it by
  # creating the container and then re-fetching it.
  describe "dropped query parameters on container create" do
    it "forwards platform, not just name" do
      client, fake = faked_client([
        http_response(201, { "Id" => "new" }),
        http_response(200, { "Id" => "new", "Name" => "/x" }),
      ])
      client.containers.create(image: "alpine", name: "x", platform: "linux/arm64")
      fake.finish

      request = CGI.unescape(fake.requests.first)
      _(request).must_include "name=x"
      _(request).must_include "platform=linux/arm64"
    end

    # The generated layer reads its parameters from Docker's specification, so
    # forgetting one is not a mistake anybody can make by hand.
    it "declares every query parameter the specification defines" do
      parameters = Docker::API::Operations.instance_method(:container_create).parameters
      names = parameters.map(&:last)

      _(names).must_include :name
      _(names).must_include :platform
      _(names).must_include :body
    end
  end

  # docker-api 2.0.0 has a Container.get unreliable enough that kitchen-dokken
  # substitutes Container.all plus a client-side name match.
  describe "fetching a container by name" do
    it "inspects the container directly instead of listing them all" do
      client, fake = faked_client([http_response(200, { "Id" => "abc", "Name" => "/dokken-x" })])
      _(client.containers.get("dokken-x").name).must_equal "dokken-x"
      fake.finish

      _(fake.requests.first).must_include "/containers/dokken-x/json"
      _(fake.requests.first).wont_include "/containers/json"
    end
  end

  # Docker.url= and Docker.creds= are process-global in docker-api, so a second
  # caller inherits or clobbers the first caller's daemon. kitchen-dokken caches
  # docker_info per host precisely because of this.
  describe "process-global state" do
    it "keeps two clients pointed at two daemons completely independent" do
      a = Docker::API::Client.new(url: "tcp://a:2375", api_version: "1.55")
      b = Docker::API::Client.new(url: "tcp://b:2375", api_version: "1.55")

      _(a.config.url).must_equal "tcp://a:2375"
      _(b.config.url).must_equal "tcp://b:2375"
      _(a.connection.transport.host).must_equal "a"
      _(b.connection.transport.host).must_equal "b"
      _(a.connection).wont_be_same_as b.connection
    end

    it "offers no way to change a daemon out from under a live client" do
      %i{url= options= creds= reset! reset_connection!}.each do |setter|
        _(Docker::API).wont_respond_to setter
        _(Docker::API::Client).wont_respond_to setter
      end
    end

    it "resolves registry credentials per call rather than from a global store" do
      _(Docker::API::Auth).must_respond_to :resolve
      _(Docker::API::Auth).wont_respond_to :creds=
    end
  end

  # Excon::Error::Socket reaches consumer rescue clauses in docker-api, coupling
  # callers to an implementation detail they never chose.
  describe "leaking the HTTP library" do
    it "never lets an Errno escape as itself" do
      client = Docker::API::Client.new(url: "unix:///nonexistent-docker.sock", api_version: "1.55")

      error = _ { client.system.info }.must_raise Docker::API::ConnectionError
      _(error).wont_be_kind_of SystemCallError
      _(error.cause).must_be_kind_of SystemCallError
    end

    it "loads no HTTP gem at all, so there is nothing to leak" do
      _($LOADED_FEATURES.grep(/excon|faraday|typhoeus|httparty/)).must_be_empty
    end

    it "declares no runtime dependencies" do
      spec = Gem::Specification.load("docker-api-ng.gemspec")
      _(spec.runtime_dependencies).must_be_empty
    end
  end

  # kitchen-dokken carries a standing TODO about //./pipe/docker_engine because
  # docker-api never grew named pipe support.
  describe "Windows named pipes" do
    it "builds a named-pipe transport from a npipe URL" do
      transport = Docker::API::Transport.for(url: "npipe:////./pipe/docker_engine")

      _(transport).must_be_kind_of Docker::API::Transport::NamedPipe
      _(transport.path).must_equal "//./pipe/docker_engine"
    end

    it "defaults to the named pipe on Windows" do
      _(Docker::API::Config::DEFAULT_WINDOWS_PIPE).must_include "pipe/docker_engine"
    end
  end

  # The docker-api gem owns ::Docker and reopens it with `extend self`. A
  # gradual migration needs both gems loadable in one process.
  describe "coexistence with docker-api" do
    it "adds nothing to ::Docker" do
      _(::Docker.methods(false)).must_be_empty
      _(::Docker.singleton_class.instance_methods(false)).must_be_empty
    end

    it "puts everything under Docker::API" do
      _(Docker::API::Client.name).must_equal "Docker::API::Client"
      _(defined?(::Docker::Container)).must_be_nil
      _(defined?(::Docker::Connection)).must_be_nil
    end
  end
end
