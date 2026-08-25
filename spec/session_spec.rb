# frozen_string_literal: true

require "spec_helper"

describe Docker::API::Session do
  it "drives a real HTTP exchange over a transport-supplied socket" do
    fake = Docker::API::Transport::Fake.new([http_response(200, { "ApiVersion" => "1.55" })])
    session = Docker::API::Session.new(fake, read_timeout: 5, open_timeout: 5)

    response = session.start { |http| http.request(Net::HTTP::Get.new("/v1.55/version")) }

    _(response.code).must_equal "200"
    _(JSON.parse(response.body)["ApiVersion"]).must_equal "1.55"
    fake.finish
    _(fake.requests.first).must_include "GET /v1.55/version"
  end

  # Getting chunked decoding for free is the reason for subclassing Net::HTTP
  # rather than writing an HTTP client.
  it "decodes a chunked body without the caller knowing" do
    fake = Docker::API::Transport::Fake.new([
      "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n5\r\nhello\r\n5\r\nworld\r\n0\r\n\r\n",
    ])
    session = Docker::API::Session.new(fake, read_timeout: 5, open_timeout: 5)

    response = session.start { |http| http.request(Net::HTTP::Get.new("/x")) }
    _(response.body).must_equal "helloworld"
  end
end
