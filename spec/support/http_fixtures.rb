# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

# Builders for the raw HTTP bytes that Transport::Fake serves.
#
# Tests state what the daemon says on the wire, not what some double returns,
# so a change in how responses are parsed is caught here rather than papered
# over by a mock that agrees with the implementation.
module HTTPFixtures
  # Reason phrases for the statuses these fixtures use. Net::HTTP exposes a
  # table of its own, but not under a name that is stable across the versions
  # this gem supports, and nothing here needs more than a handful.
  REASONS = {
    101 => "UPGRADED", 200 => "OK", 201 => "Created", 204 => "No Content",
    304 => "Not Modified", 400 => "Bad Request", 401 => "Unauthorized",
    403 => "Forbidden", 404 => "Not Found", 409 => "Conflict",
    500 => "Internal Server Error", 503 => "Service Unavailable",
  }.freeze

  # @param status [Integer] the HTTP status
  # @param body [Hash, Array, String, nil] a JSON body, or a raw string
  # @param headers [Hash] extra response headers
  # @return [String] raw HTTP response bytes
  def http_response(status = 200, body = nil, headers: {})
    payload = body.is_a?(String) || body.nil? ? body.to_s : JSON.generate(body)
    head = {
      "Content-Type" => body.is_a?(String) || body.nil? ? "text/plain" : "application/json",
      "Content-Length" => payload.bytesize.to_s,
    }.merge(headers)

    lines = ["HTTP/1.1 #{status} #{REASONS.fetch(status, "Unknown")}"]
    head.each { |key, value| lines << "#{key}: #{value}" }
    "#{lines.join("\r\n")}\r\n\r\n#{payload}"
  end

  # A /_ping answer, which is how version negotiation learns what to ask for.
  #
  # @param api_version [String] the version the daemon claims
  # @return [String] raw HTTP response bytes
  def ping_response(api_version: Docker::API::MAX_API_VERSION)
    http_response(200, "OK", headers: {
      "Api-Version" => api_version,
      "Docker-Experimental" => "false",
      "Ostype" => "linux",
    })
  end

  # Docker's multiplexed frame: a stream id, three padding bytes, a big-endian
  # length, then the payload.
  #
  # @param stream_id [Integer] 0 stdin, 1 stdout, 2 stderr
  # @param payload [String]
  # @return [String] raw frame bytes
  def stream_frame(stream_id, payload)
    [stream_id, 0, 0, 0, payload.bytesize].pack("CCCCN") + payload
  end

  # Build a client whose daemon is a script rather than a socket.
  #
  # The API version is pinned so tests do not have to script a ping they are
  # not interested in.
  #
  # @param responses [Array<String>] raw HTTP responses, in order
  # @return [Array(Docker::API::Client, Docker::API::Transport::Fake)]
  def faked_client(responses, api_version: Docker::API::MAX_API_VERSION)
    fake = Docker::API::Transport::Fake.new(responses)
    [Docker::API::Client.new(transport: fake, api_version: api_version), fake]
  end
end

module Minitest
  class Test
    include HTTPFixtures
  end
end
