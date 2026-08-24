# frozen_string_literal: true

require "spec_helper"

describe Docker::API::Connection do
  def connection_for(responses, **options)
    fake = Docker::API::Transport::Fake.new(responses)
    [Docker::API::Connection.new(transport: fake, **options), fake]
  end

  describe "version negotiation" do
    it "meets an older daemon where it is" do
      connection, = connection_for([ping_response(api_version: "1.44")])
      _(connection.api_version).must_equal "1.44"
    end

    # Above what the vendored specification describes, the generated layer does
    # not know what to ask for, so there is nothing to gain by asking.
    it "never negotiates above the version this gem vendors" do
      connection, = connection_for([ping_response(api_version: "1.99")])
      _(connection.api_version).must_equal Docker::API::MAX_API_VERSION
    end

    it "refuses a daemon below the floor, naming both versions" do
      connection, = connection_for([ping_response(api_version: "1.24")])
      error = _ { connection.api_version }.must_raise Docker::API::VersionUnsupported

      _(error.message).must_include "1.24"
      _(error.message).must_include Docker::API::MIN_API_VERSION
    end

    it "does not ping at all when a version is pinned" do
      connection, fake = connection_for([http_response(200, {})], api_version: "1.44")
      connection.request(:get, "/info")
      fake.finish

      _(fake.requests.size).must_equal 1
      _(fake.requests.first).must_include "/v1.44/info"
    end

    it "sends unprefixed paths when versioning is disabled" do
      connection, fake = connection_for([http_response(200, {})], api_version: :none)
      connection.request(:get, "/info")
      fake.finish

      _(fake.requests.first).must_include "GET /info"
    end

    it "negotiates once, not once per request" do
      connection, fake = connection_for([
        ping_response(api_version: "1.55"), http_response(200, {}), http_response(200, {}),
      ])
      connection.request(:get, "/info")
      connection.request(:get, "/version")
      fake.finish

      _(fake.requests.count { |r| r.include?("/_ping") }).must_equal 1
    end

    it "does not version-prefix the ping itself, which would be circular" do
      connection, fake = connection_for([ping_response])
      connection.api_version
      fake.finish

      _(fake.requests.first).must_include "GET /_ping HTTP"
    end
  end

  describe "issuing requests" do
    it "prefixes the negotiated version onto the path" do
      connection, fake = connection_for([http_response(200, [])], api_version: "1.55")
      connection.request(:get, "/containers/json", query: { "all" => true })
      fake.finish

      _(fake.requests.first).must_include "GET /v1.55/containers/json?all=true"
    end

    it "returns a response carrying status, headers and body" do
      connection, = connection_for([http_response(200, { "Name" => "moby" })], api_version: "1.55")
      response = connection.request(:get, "/info")

      _(response.status).must_equal 200
      _(response.json["Name"]).must_equal "moby"
      _(response["content-type"]).must_equal "application/json"
      _(response.success?).must_equal true
    end

    it "JSON-encodes a hash body and says so in the content type" do
      connection, fake = connection_for([http_response(201, {})], api_version: "1.55")
      connection.request(:post, "/containers/create", body: { "Image" => "alpine" }, expects: [201])
      fake.finish

      _(fake.requests.first).must_include "Content-Type: application/json"
      _(fake.requests.first).must_include '{"Image":"alpine"}'
    end

    it "identifies itself in the User-Agent" do
      connection, fake = connection_for([http_response(200, {})], api_version: "1.55")
      connection.request(:get, "/info")
      fake.finish

      _(fake.requests.first).must_include "docker-api-ng/#{Docker::API::VERSION}"
    end
  end

  describe "when the daemon says no" do
    it "raises the mapped error with the operation attached" do
      connection, = connection_for(
        [http_response(404, { "message" => "No such container: nope" })], api_version: "1.55"
      )
      error = _ {
        connection.request(:get, "/containers/nope/json", operation: "container_inspect")
      }.must_raise Docker::API::NotFound

      _(error.message).must_include "container_inspect"
      _(error.message).must_include "No such container"
    end

    it "treats a status outside expects as a failure even when it is a 2xx" do
      connection, = connection_for([http_response(200, {})], api_version: "1.55")
      _ {
        connection.request(:post, "/containers/x/start", expects: [204], operation: "container_start")
      }.must_raise Docker::API::Error
    end

    it "accepts a documented non-200 success" do
      connection, = connection_for([http_response(204, nil)], api_version: "1.55")
      response = connection.request(:delete, "/containers/x", expects: [204])

      _(response.status).must_equal 204
    end

    # docker-api leaks Excon::Error::Socket to callers. Nothing below the
    # abstraction should reach a rescue clause here.
    it "converts a dead socket into a gem error, keeping the cause" do
      transport = Docker::API::Transport::Unix.new(path: "/nonexistent/docker.sock")
      connection = Docker::API::Connection.new(transport: transport, api_version: "1.55")

      error = _ { connection.request(:get, "/info") }.must_raise Docker::API::ConnectionError
      _(error).wont_be_kind_of SystemCallError
    end
  end

  describe "streaming" do
    it "yields body chunks to a block instead of buffering them" do
      body = stream_frame(1, "hello")
      connection, = connection_for([
        "HTTP/1.1 200 OK\r\nContent-Length: #{body.bytesize}\r\n\r\n#{body}",
      ], api_version: "1.55")

      chunks = []
      response = connection.request(:get, "/containers/x/logs") { |chunk| chunks << chunk }

      _(chunks.join).must_equal body
      _(response.body).must_be_empty
    end

    # A streamed error must not be handed to the caller's block as if it were
    # output; it has to be read and raised.
    it "buffers and raises an error response even when a block was given" do
      connection, = connection_for(
        [http_response(404, { "message" => "no such container" })], api_version: "1.55"
      )

      chunks = []
      _ {
        connection.request(:get, "/containers/x/logs", operation: "container_logs") { |c| chunks << c }
      }.must_raise Docker::API::NotFound
      _(chunks).must_be_empty
    end
  end

  describe "logging" do
    it "logs one line per request when given a logger" do
      logged = []
      logger = Object.new
      logger.define_singleton_method(:debug) { |*_args, &block| logged << block.call }

      connection, = connection_for([http_response(200, {})], api_version: "1.55")
      connection.instance_variable_set(:@logger, logger)
      connection.request(:get, "/info", operation: "system_info")

      _(logged.first).must_include "system_info"
      _(logged.first).must_include "GET /v1.55/info"
    end
  end
end
