# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Docker
  module API
    # What the daemon said, before anything has interpreted it.
    #
    # The status is kept alongside the body because Docker uses it to carry
    # meaning: 204 for a successful delete, 304 for "already in that state".
    # A layer that returned only a parsed body would throw that away.
    class Response
      # @return [Integer] the HTTP status
      attr_reader :status

      # @return [Hash{String => String}] response headers, downcased keys
      attr_reader :headers

      # @return [String] the raw body. Empty when the body was streamed to a
      #   block instead of buffered.
      attr_reader :body

      # @param status [Integer] the HTTP status
      # @param headers [Hash] response headers in any casing
      # @param body [String, nil] the raw body
      def initialize(status:, headers: {}, body: nil)
        @status = Integer(status)
        @headers = normalize(headers)
        @body = body.to_s
      end

      # The body parsed as JSON.
      #
      # @return [Hash, Array, nil] the parsed body, or nil when there was none
      # @raise [Docker::API::StreamError] if the body is not valid JSON
      def json
        return @json if defined?(@json)

        @json = if body.empty?
                  nil
                else
                  begin
                    JSON.parse(body)
                  rescue JSON::ParserError => e
                    raise StreamError.new(
                      "expected JSON from the daemon but could not parse it: #{e.message}",
                      status: status, response: self
                    )
                  end
                end
      end

      # The body parsed as JSON, when a document is required rather than
      # merely hoped for.
      #
      # {#json} answers nil for an empty body, which is right: 204 and 304 are
      # ordinary Docker answers and carry nothing. But most callers immediately
      # index the result -- `.json["Id"]`, `.json["StatusCode"]` -- and against
      # an empty body that is `NoMethodError: undefined method '[]' for nil`, a
      # bare Ruby error escaping the hierarchy this gem promises is the only
      # thing a caller has to rescue.
      #
      # Reaching this means a daemon, proxy or API-compatible shim answered a
      # documented-success status with no body, so name that rather than
      # letting a nil propagate to whichever accessor touches it first.
      #
      # @return [Hash, Array] the parsed body
      # @raise [Docker::API::StreamError] if the body was empty or unparseable
      def json!
        parsed = json
        return parsed unless parsed.nil?

        raise StreamError.new(
          "the daemon answered HTTP #{status} with an empty body, but this call needs a JSON document",
          status: status, response: self
        )
      end

      # @return [Boolean] whether the status is in the 2xx range
      def success?
        (200..299).cover?(status)
      end

      # @return [String, nil] the value of a header, case-insensitively
      def [](name)
        headers[name.to_s.downcase]
      end

      # @return [String]
      def to_s
        "#<Docker::API::Response status=#{status} bytes=#{body.bytesize}>"
      end
      alias_method :inspect, :to_s

      private

      # Header casing is not guaranteed by anything, so it is normalised once
      # here rather than being guessed at every call site.
      #
      # @param headers [Hash]
      # @return [Hash{String => String}]
      def normalize(headers)
        headers.each_with_object({}) do |(key, value), out|
          out[key.to_s.downcase] = value.is_a?(Array) ? value.first : value
        end.freeze
      end
    end
  end
end
