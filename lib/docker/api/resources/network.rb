# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Docker
  module API
    # A network on the daemon.
    class Network < Resource
      # @return [String, nil] the network's name
      def name
        detail("Name")
      end

      # @return [String, nil] "bridge", "overlay", "host", and so on
      def driver
        detail("Driver")
      end

      # @return [Boolean] whether the network has IPv6 enabled
      def ipv6?
        detail("EnableIPv6") == true
      end

      # @return [Hash] containers attached to this network, keyed by id
      def containers
        detail("Containers") || {}
      end

      # @return [Array<Hash>] the network's IPAM configuration
      def subnets
        detail("IPAM.Config") || []
      end

      # @return [self]
      def reload
        replace_raw(operations.network_inspect(id: id || name).json)
      end

      # Attach a container to this network.
      #
      # @param container [String, Docker::API::Container] the container
      # @param aliases [Array<String>] additional names it answers to here
      # @param ipv4_address [String, nil] a fixed address to assign
      # @param ipv6_address [String, nil] a fixed address to assign
      # @return [self]
      #
      # @example
      #   network.connect(container, aliases: %w{web web.local})
      def connect(container, aliases: [], ipv4_address: nil, ipv6_address: nil)
        endpoint = {}
        endpoint["Aliases"] = aliases unless aliases.nil? || aliases.empty?
        endpoint["IPAMConfig"] = {
          "IPv4Address" => ipv4_address, "IPv6Address" => ipv6_address
        }.compact
        endpoint.delete("IPAMConfig") if endpoint["IPAMConfig"].empty?

        body = { "Container" => container_id(container) }
        body["EndpointConfig"] = endpoint unless endpoint.empty?

        operations.network_connect(id: id, body: body)
        self
      end

      # @param container [String, Docker::API::Container] the container
      # @param force [Boolean] disconnect even if the container is running
      # @return [self]
      def disconnect(container, force: false)
        operations.network_disconnect(
          id: id, body: { "Container" => container_id(container), "Force" => force }
        )
        self
      end

      # @return [void]
      def remove
        operations.network_delete(id: id)
        nil
      end

      private

      # @param container [String, Docker::API::Container]
      # @return [String]
      def container_id(container)
        container.respond_to?(:id) ? container.id : container.to_s
      end
    end
  end
end
