# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Docker
  module API
    # Turns Ruby values into the query strings the Engine API expects.
    #
    # Docker's conventions are specific enough to be worth centralising, and
    # they are not uniform:
    #
    # * Booleans travel as the literal strings "true" and "false".
    # * Structured parameters such as `filters` are declared in the API
    #   specification as strings holding a JSON document, so a Hash becomes one
    #   JSON-encoded value.
    # * A handful of parameters -- the `platform` and `type` parameters of the
    #   image and system endpoints -- are declared as arrays with
    #   `collectionFormat: multi`, so an Array becomes a repeated key rather
    #   than one JSON value.
    #
    # Getting this wrong does not raise: the daemon ignores a parameter it
    # cannot parse and quietly does something else, which is the failure mode
    # that makes it worth encoding in one place.
    module Query
      module_function

      # Encode a parameter hash as a URL query fragment.
      #
      # Nil values are dropped rather than sent empty, because an empty value
      # is not the same as an absent one to the daemon: `?all=` is a parse
      # error where omitting `all` is a default.
      #
      # @param params [Hash] parameters in Ruby types
      # @return [String] a fragment beginning with "?", or "" when nothing
      #   survived, so callers can concatenate unconditionally
      #
      # @example A boolean and a JSON-encoded filter
      #   Query.encode(all: true, filters: { "status" => ["running"] })
      #   #=> "?all=true&filters=%7B%22status%22%3A%5B%22running%22%5D%7D"
      #
      # @example An array parameter, repeated rather than JSON-encoded
      #   Query.encode(platform: ["linux/amd64", "linux/arm64"])
      #   #=> "?platform=linux%2Famd64&platform=linux%2Farm64"
      def encode(params)
        pairs = (params || {}).reject { |_, value| value.nil? }
          .flat_map { |key, value| pairs_for(key.to_s, value) }

        return "" if pairs.empty?

        "?#{URI.encode_www_form(pairs)}"
      end

      # @param key [String] the wire parameter name
      # @param value [Object] the Ruby value
      # @return [Array<Array(String, String)>] one or more key/value pairs
      # @api private
      def pairs_for(key, value)
        return value.map { |element| [key, serialize(element)] } if value.is_a?(Array)

        [[key, serialize(value)]]
      end

      # @param value [Object]
      # @return [String] the daemon's expected wire form for a single value
      # @api private
      def serialize(value)
        case value
        when true, false then value.to_s
        when Hash then JSON.generate(value)
        else value.to_s
        end
      end
    end
  end
end
