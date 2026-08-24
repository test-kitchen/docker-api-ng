# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Docker
  module API
    # Shared behaviour for the objects the daemon describes: containers,
    # images, networks and volumes.
    #
    # The Engine API returns different shapes for the same object depending on
    # how you asked. `GET /containers/json` answers with `Names: ["/web"]`;
    # `GET /containers/{id}/json` answers with `Name: "/web"`. A client that
    # simply exposes whichever payload it happened to receive pushes that
    # difference onto every caller, which is why code written against such a
    # client ends up reading `info["Names"]` in one place and `[:Name]` in
    # another and breaking when the two are swapped.
    #
    # Resources here normalise. {#name} answers the same thing regardless of
    # origin, and an object built from a list marks itself {#partial?}: the
    # first accessor that needs detail the list did not carry fetches it once,
    # rather than returning nil and letting the caller guess why.
    #
    # @abstract Subclass and implement {#reload}.
    class Resource
      # @return [Docker::API::Client] the client this resource came from
      attr_reader :client

      # @param client [Docker::API::Client] the client to issue further calls on
      # @param raw [Hash] the daemon's payload
      # @param partial [Boolean] whether the payload came from a list endpoint
      def initialize(client:, raw:, partial: false)
        @client = client
        @raw = raw || {}
        @partial = partial
        @reloaded = false
        @stale = false
      end

      # The daemon's payload, exactly as it arrived.
      #
      # Always available, so nothing this gem does not model is out of reach.
      #
      # @return [Hash]
      attr_reader :raw

      # @return [Boolean] whether this came from a list and may lack detail
      def partial?
        @partial
      end

      # @return [String, nil] the object's id
      def id
        raw["Id"] || raw["ID"]
      end

      # Read a key straight from the payload, with no normalisation.
      #
      # @param key [String] a key as the daemon spells it
      # @return [Object, nil]
      def [](key)
        raw[key]
      end

      # @return [Boolean] whether an action has changed this object since the
      #   payload in hand was fetched
      def stale?
        @stale
      end

      # Re-fetch this object from the daemon.
      #
      # @return [self]
      def reload
        raise NotImplementedError, "#{self.class} must implement #reload"
      end

      # @return [String]
      def to_s
        "#<#{self.class.name} id=#{id.to_s[0, 12]}#{partial? ? " partial" : ""}>"
      end
      alias_method :inspect, :to_s

      # @param other [Object]
      # @return [Boolean]
      def ==(other)
        other.is_a?(self.class) && !id.nil? && id == other.id
      end
      alias_method :eql?, :==

      # @return [Integer]
      def hash
        [self.class, id].hash
      end

      private

      # Read the first of several possible keys, fetching detail if needed.
      #
      # Every key is tried against the payload already in hand before any
      # request is considered. That ordering is the whole point: a container
      # from a list carries its name under "Names", so asking for
      # `detail("Name", "Names")` must answer from memory rather than spending
      # a round trip rediscovering what it was already told.
      #
      # A partial resource reloads at most once, no matter how many accessors
      # ask for something it does not have. A complete resource never reloads:
      # if the daemon did not report the field, it is genuinely absent, and a
      # second identical request would only confirm that more slowly.
      #
      # @param keys [Array<String>] keys to try, in order of preference
      # @return [Object, nil]
      def detail(*keys)
        refresh_if_stale
        found = first_present(keys)
        return found unless found.nil?
        return nil unless partial? && !@reloaded

        @reloaded = true
        reload
        first_present(keys)
      end

      # Note that an action just changed this object on the daemon.
      #
      # Starting a container does not update the payload we are holding, so
      # without this a caller who starts a container and then asks its state is
      # told "created" -- true when we fetched it, and useless now. The refresh
      # is deferred rather than immediate, so an action followed by no question
      # still costs one request rather than two.
      #
      # @return [self]
      def mark_stale
        @stale = true
        self
      end

      # @return [void]
      def refresh_if_stale
        return unless @stale

        @stale = false
        @reloaded = false
        reload
      end

      # @param keys [Array<String>]
      # @return [Object, nil]
      def first_present(keys)
        keys.each do |key|
          value = key.include?(".") ? raw.dig(*key.split(".")) : raw[key]
          return value unless value.nil?
        end
        nil
      end

      # Replace the payload after a re-fetch.
      #
      # @param payload [Hash]
      # @return [self]
      def replace_raw(payload)
        @raw = payload || {}
        @partial = false
        @stale = false
        self
      end

      # @return [Docker::API::Operations]
      def operations
        client.operations
      end
    end
  end
end
