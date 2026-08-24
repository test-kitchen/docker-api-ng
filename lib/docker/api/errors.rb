# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Docker
  module API
    # The root of every error this gem raises.
    #
    # Nothing beneath the abstraction escapes: no `Errno`, no `OpenSSL`
    # exception, no `Net::` class and no `JSON::ParserError` reaches a caller's
    # rescue clause. The original is always retained as {#cause}, so nothing is
    # lost -- but consumers get to rescue one hierarchy instead of coupling
    # themselves to whichever HTTP library happens to be underneath.
    #
    # @example Rescuing anything this gem can raise
    #   begin
    #     client.containers.get("missing")
    #   rescue Docker::API::Error => e
    #     warn "#{e.operation} failed: #{e.message}"
    #   end
    class Error < StandardError
      # @return [String, nil] the operation that failed, e.g. "container_start"
      attr_reader :operation

      # @return [Integer, nil] the HTTP status the daemon returned
      attr_reader :status

      # @return [Docker::API::Response, nil] the response, when there was one
      attr_reader :response

      # @param message [String, nil] a message, or nil to compose one
      # @param operation [String, Symbol, nil] the operation that failed
      # @param status [Integer, nil] the HTTP status
      # @param response [Docker::API::Response, nil] the response
      def initialize(message = nil, operation: nil, status: nil, response: nil)
        @operation = operation&.to_s
        @status = status
        @response = response
        super(message || compose_message)
      end

      # Build the error class appropriate to an HTTP status.
      #
      # @param status [Integer] the HTTP status the daemon returned
      # @param operation [String, Symbol, nil] the operation that failed
      # @param response [Docker::API::Response, nil] the response
      # @return [Docker::API::Error] an instance of the mapped subclass
      def self.for(status:, operation: nil, response: nil)
        klass_for(status).new(nil, operation: operation, status: status, response: response)
      end

      # @param status [Integer] an HTTP status
      # @return [Class] the error class that status maps to
      # @api private
      def self.klass_for(status)
        STATUS_MAP.fetch(status) do
          case status
          when 400..499 then ClientError
          when 500..599 then ServerError
          else Error
          end
        end
      end
      private_class_method :klass_for

      private

      # Compose the most informative message available: what was attempted,
      # what the daemon said about it, and the status it said it with.
      #
      # @return [String]
      def compose_message
        parts = []
        parts << (operation ? "#{operation} failed" : "request failed")
        parts << "(HTTP #{status})" if status
        detail = daemon_message
        parts << ": #{detail}" if detail && !detail.empty?
        parts.join(" ").sub(" :", ":")
      end

      # The daemon reports its own reason in a JSON `message` field. Fall back
      # to the raw body when the response is not JSON, because an unparsed body
      # is still more use to a human than nothing at all.
      #
      # @return [String, nil]
      def daemon_message
        return nil if response.nil?

        body = response.body
        return nil if body.nil? || body.empty?

        parsed = begin
          JSON.parse(body)
                 rescue JSON::ParserError
                   nil
        end

        return body.strip unless parsed.is_a?(Hash)

        parsed["message"] || parsed["Message"] || body.strip
      end
    end

    # The daemon could not be reached at all: refused, reset, unresolvable, or
    # a TLS handshake that failed.
    class ConnectionError < Error; end

    # The daemon accepted the connection but did not answer in time.
    class TimeoutError < Error; end

    # The request was wrong. 4xx.
    class ClientError < Error; end

    # 400 -- the daemon could not parse or accept the request.
    class BadRequest < ClientError; end

    # 401 -- authentication is required or was rejected.
    class Unauthorized < ClientError; end

    # 403 -- the daemon understood but refuses.
    class Forbidden < ClientError; end

    # 404 -- no such container, image, network, volume or endpoint.
    class NotFound < ClientError; end

    # 304 -- the requested change was already true. Docker returns this for,
    # among others, starting an already-running container, which is why it is
    # grouped with the client errors rather than treated as a redirect.
    class NotModified < ClientError; end

    # 409 -- the request conflicts with the daemon's current state, such as a
    # container name already in use.
    class Conflict < ClientError; end

    # 5xx -- the daemon failed while handling a request it accepted.
    class ServerError < Error; end

    # The daemon speaks an API version this gem cannot work with.
    class VersionUnsupported < Error; end

    # A response stream was malformed, truncated, or not the format the
    # endpoint promised.
    class StreamError < Error; end

    # Statuses with a specific meaning worth its own class. Anything else falls
    # back to ClientError or ServerError by range.
    #
    # @api private
    STATUS_MAP = {
      304 => NotModified,
      400 => BadRequest,
      401 => Unauthorized,
      403 => Forbidden,
      404 => NotFound,
      409 => Conflict,
    }.freeze
  end
end
