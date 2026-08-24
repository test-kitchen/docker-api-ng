# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Docker
  module API
    # The networks on a daemon.
    class Networks < Collection
      # @param filters [Hash, nil] daemon-side filters
      # @return [Array<Docker::API::Network>] partial resources
      def all(filters: nil)
        operations.network_list(filters: filters)
          .json!.map { |payload| Network.new(client: client, raw: payload, partial: true) }
      end

      # @param id [String] a name or id
      # @param verbose [Boolean] include service details
      # @param scope [String, nil] "swarm", "global" or "local"
      # @return [Docker::API::Network]
      # @raise [Docker::API::NotFound] if there is no such network
      def get(id, verbose: false, scope: nil)
        Network.new(
          client: client,
          raw: operations.network_inspect(id: id, verbose: verbose, scope: scope).json,
          partial: false
        )
      end

      # Create a network.
      #
      # @param name [String] the network's name
      # @param driver [String, nil] "bridge", "overlay", and so on
      # @param ipv6 [Boolean] enable IPv6 addressing
      # @param internal [Boolean] withhold external access
      # @param attachable [Boolean] allow manual container attachment
      # @param labels [Hash, nil] labels for the network
      # @param ipam [Hash, nil] an IPAM configuration
      # @param options [Hash, nil] driver-specific options
      # @param attributes [Hash] any further body attributes
      # @return [Docker::API::Network]
      #
      # @example
      #   client.networks.create("dokken", ipv6: true,
      #     ipam: { "Config" => [{ "Subnet" => "fd00::/64" }] })
      def create(name, driver: nil, ipv6: false, internal: false, attachable: false,
        labels: nil, ipam: nil, options: nil, **attributes)
        body = Body.build(attributes).merge(
          "Name" => name, "Driver" => driver, "EnableIPv6" => ipv6,
          "Internal" => internal, "Attachable" => attachable,
          "Labels" => labels, "IPAM" => ipam, "Options" => options
        ).compact

        get(operations.network_create(body: body).json!["Id"])
      end

      # Fetch a network by name, creating it if it does not exist.
      #
      # Two processes racing to create the same shared network is ordinary
      # rather than exceptional -- parallel test suites do it constantly -- so
      # losing that race is treated as success and the winner's network is
      # returned.
      #
      # @param name [String] the network's name
      # @param attributes [Hash] passed to {#create} when creating
      # @return [Docker::API::Network]
      def ensure(name, **attributes)
        found = find(name)
        return found if found

        begin
          create(name, **attributes)
        rescue Conflict
          get(name)
        end
      end

      # @param filters [Hash, nil] which networks to consider
      # @return [Hash] what was deleted
      def prune(filters: nil)
        operations.network_prune(filters: filters).json
      end
    end
  end
end
