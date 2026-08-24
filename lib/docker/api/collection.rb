# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Docker
  module API
    # Shared behaviour for the collections hanging off a {Docker::API::Client}.
    #
    # Collections are thin by design: each method is one call into the
    # generated operations layer plus whatever wrapping makes the result
    # pleasant. Keeping them thin is what stops the ergonomic layer from
    # drifting away from the API it is supposed to be sugar for.
    #
    # @abstract
    class Collection
      # @return [Docker::API::Client] the client this collection belongs to
      attr_reader :client

      # @param client [Docker::API::Client]
      def initialize(client)
        @client = client
      end

      # Fetch one object, or nil if the daemon has never heard of it.
      #
      # The distinction from `get` is deliberate. Asking for something by a
      # name a user typed is a question; asking for something you just created
      # is an assertion. `find` answers the question, `get` makes the
      # assertion and raises when it turns out to be false.
      #
      # @param id [String] a name or id
      # @return [Docker::API::Resource, nil]
      def find(id)
        get(id)
      rescue NotFound
        nil
      end

      # @param id [String] a name or id
      # @return [Boolean] whether the object exists
      def exist?(id)
        !find(id).nil?
      end

      # @return [String]
      def to_s
        "#<#{self.class.name}>"
      end
      alias_method :inspect, :to_s

      private

      # @return [Docker::API::Operations]
      def operations
        client.operations
      end
    end
  end
end
