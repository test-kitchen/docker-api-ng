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

    it "declares no runtime dependencies" do
      spec = Gem::Specification.load("docker-api-ng.gemspec")
      _(spec.runtime_dependencies).must_be_empty
    end
  end

  # kitchen-dokken carries a standing TODO about //./pipe/docker_engine because
  # docker-api never grew named pipe support.
  describe "Windows named pipes" do
    # Asserted as a literal rather than against the constant. Comparing
    # default_url to DEFAULT_WINDOWS_PIPE only proves the two agree with each
    # other, so a typo in the constant would pass. This value is an external
    # contract -- it is the pipe Docker Desktop for Windows actually publishes.
    it "resolves the default daemon URL to the named pipe on Windows" do
      Docker::API::Config.stub(:windows?, true) do
        _(Docker::API::Config.default_url).must_equal "npipe:////./pipe/docker_engine"
      end
    end

    it "resolves it to the unix socket everywhere else" do
      Docker::API::Config.stub(:windows?, false) do
        _(Docker::API::Config.default_url).must_equal "unix:///var/run/docker.sock"
      end
    end
  end

  # The docker-api gem owns ::Docker and reopens it with `extend self`. A
  # gradual migration needs both gems loadable in one process.
  describe "coexistence with docker-api" do
    it "adds nothing to ::Docker" do
      _(::Docker.methods(false)).must_be_empty
      _(::Docker.singleton_class.instance_methods(false)).must_be_empty
    end
  end
end
