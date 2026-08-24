# frozen_string_literal: true

require "spec_helper"

# Interactive exec and attach need the socket itself. This path deliberately
# does not go through Net::HTTP, because Net::BufferedIO may already have read
# ahead past the response headers, and prising a buffered socket back out of
# the stdlib is the problem that produced docker-api's custom Excon middleware.
describe "Docker::API::Connection#hijack" do
  def upgrade_response(payload)
    "HTTP/1.1 101 UPGRADED\r\n" \
      "Content-Type: application/vnd.docker.raw-stream\r\n" \
      "Connection: Upgrade\r\nUpgrade: tcp\r\n\r\n#{payload}"
  end

  it "returns the socket positioned at the stream, not at the headers" do
    payload = stream_frame(1, "interactive")
    fake = Docker::API::Transport::Fake.new([upgrade_response(payload)])
    connection = Docker::API::Connection.new(transport: fake, api_version: "1.55")

    io = connection.hijack(:post, "/exec/abc/start", operation: "exec_start")
    _(io.read).must_equal payload
  end

  it "asks for the upgrade the daemon requires" do
    fake = Docker::API::Transport::Fake.new([upgrade_response("")])
    connection = Docker::API::Connection.new(transport: fake, api_version: "1.55")

    connection.hijack(:post, "/exec/abc/start", operation: "exec_start")
    fake.finish

    request = fake.requests.first
    _(request).must_include "POST /v1.55/exec/abc/start"
    _(request).must_include "Connection: Upgrade"
    _(request).must_include "Upgrade: tcp"
  end

  it "accepts a plain 200, which is what the daemon sends without an upgrade" do
    fake = Docker::API::Transport::Fake.new([
      "HTTP/1.1 200 OK\r\nContent-Type: application/vnd.docker.raw-stream\r\n\r\nbody",
    ])
    connection = Docker::API::Connection.new(transport: fake, api_version: "1.55")

    _(connection.hijack(:post, "/containers/x/attach").read).must_equal "body"
  end

  it "raises rather than handing back a socket when the daemon refuses" do
    fake = Docker::API::Transport::Fake.new([
      http_response(500, { "message" => "cannot attach" }),
    ])
    connection = Docker::API::Connection.new(transport: fake, api_version: "1.55")

    error = _ {
      connection.hijack(:post, "/containers/x/attach", operation: "container_attach")
    }.must_raise Docker::API::ServerError
    _(error.message).must_include "cannot attach"
  end

  it "sends a body when one is given" do
    fake = Docker::API::Transport::Fake.new([upgrade_response("")])
    connection = Docker::API::Connection.new(transport: fake, api_version: "1.55")

    connection.hijack(:post, "/exec/abc/start", body: { "Detach" => false })
    fake.finish

    _(fake.requests.first).must_include '{"Detach":false}'
    _(fake.requests.first).must_include "Content-Length: 16"
  end
end
