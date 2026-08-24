# frozen_string_literal: true

require "spec_helper"

# Transport::Fake serves scripted responses over a real socket pair rather than
# a StringIO, because Net::BufferedIO calls read_nonblock, write and to_io on
# whatever it is handed. A double that does not honour that contract produces
# tests which pass against something the production code could never drive.
describe Docker::API::Transport::Fake do
  it "serves a scripted response over a genuine socket" do
    fake = Docker::API::Transport::Fake.new(["HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nhi"])
    io = fake.connect
    io.write("GET /_ping HTTP/1.1\r\nHost: localhost\r\n\r\n")

    _(io.read).must_include "hi"
  end

  it "records the request bytes for assertions" do
    fake = Docker::API::Transport::Fake.new([http_response(200, {})])
    io = fake.connect
    io.write("GET /v1.55/info HTTP/1.1\r\nHost: localhost\r\n\r\n")
    io.read
    fake.finish

    _(fake.requests.first).must_include "GET /v1.55/info"
  end

  it "reads a request body of the length the caller promised" do
    fake = Docker::API::Transport::Fake.new([http_response(201, {})])
    io = fake.connect
    io.write("POST /x HTTP/1.1\r\nHost: localhost\r\nContent-Length: 7\r\n\r\n{\"a\":1}")
    io.read
    fake.finish

    _(fake.requests.first).must_include '{"a":1}'
  end

  it "is a real socket, so it satisfies what Net::BufferedIO asks of one" do
    io = Docker::API::Transport::Fake.new([]).connect
    _(io).must_respond_to :read_nonblock
    _(io).must_respond_to :write
    _(io).must_respond_to :to_io
  end
end
