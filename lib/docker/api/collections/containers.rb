# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Docker
  module API
    # The containers on a daemon.
    #
    # @example
    #   client.containers.all(all: true)
    #   client.containers.create(image: "alpine:3.20", name: "scratch", cmd: %w{sleep 30})
    class Containers < Collection
      # List containers.
      #
      # @param all [Boolean] include containers that are not running
      # @param limit [Integer, nil] return only the most recent N
      # @param size [Boolean] include the filesystem size of each
      # @param filters [Hash, nil] daemon-side filters, e.g. `{ "status" => ["running"] }`
      # @return [Array<Docker::API::Container>] partial resources; accessors
      #   that need detail the list did not carry will fetch it
      def all(all: false, limit: nil, size: false, filters: nil)
        operations.container_list(all: all, limit: limit, size: size, filters: filters)
          .json!.map { |payload| Container.new(client: client, raw: payload, partial: true) }
      end

      # Fetch one container.
      #
      # @param id [String] a name or id
      # @param size [Boolean] include filesystem size information
      # @return [Docker::API::Container]
      # @raise [Docker::API::NotFound] if there is no such container
      def get(id, size: false)
        Container.new(
          client: client,
          raw: operations.container_inspect(id: id, size: size).json,
          partial: false
        )
      end

      # Create a container.
      #
      # Body attributes may be given in snake_case and are converted to the
      # daemon's spelling; keys already in the daemon's convention are passed
      # through untouched, so a configuration copied out of Docker's own
      # documentation works as-is. Only top-level keys are converted -- nested
      # maps such as `Labels` and `PortBindings` have keys that are data.
      #
      # @param name [String, nil] a name for the container
      # @param platform [String, nil] "os[/arch[/variant]]" to create for
      # @param attributes [Hash] the container configuration
      # @return [Docker::API::Container]
      #
      # @example
      #   client.containers.create(
      #     image: "alpine:3.20",
      #     name: "worker",
      #     cmd: %w{sleep 3600},
      #     env: ["LOG_LEVEL=debug"],
      #     host_config: { "Binds" => ["/data:/data:ro"] }
      #   )
      def create(name: nil, platform: nil, **attributes)
        response = operations.container_create(
          body: Body.build(attributes), name: name, platform: platform
        )
        get(response.json!["Id"])
      end

      # Remove stopped containers.
      #
      # @param filters [Hash, nil] which containers to consider
      # @return [Hash] what was deleted and how much space it freed
      def prune(filters: nil)
        operations.container_prune(filters: filters).json
      end
    end
  end
end
