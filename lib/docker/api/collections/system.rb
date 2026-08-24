# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Docker
  module API
    # The daemon itself, rather than the things it holds.
    #
    # @example
    #   client.system.info["ServerVersion"] #=> "29.7.2"
    #   client.system.ping?                 #=> true
    class System < Collection
      # @return [Hash] the daemon's full description of itself
      def info
        operations.system_info.json
      end

      # @return [Hash] versions of the daemon and its components
      def version
        operations.system_version.json
      end

      # The Engine API version in use for this client, after negotiation.
      #
      # @return [String, nil]
      def api_version
        client.connection.api_version
      end

      # @return [Boolean] whether the daemon answered
      def ping?
        client.connection.ping.success?
      rescue Error
        false
      end

      # @return [Hash] disk usage by images, containers, volumes and cache
      def data_usage(type: nil, verbose: false)
        operations.system_data_usage(type: type, verbose: verbose).json
      end

      # Whether the daemon is Podman wearing Docker's API.
      #
      # Worth knowing, because Podman implements most of this API and diverges
      # in enough places -- notably around networking and rootless behaviour --
      # that callers sometimes need to branch on it.
      #
      # @return [Boolean]
      def podman?
        Array(version["Components"]).any? { |c| c["Name"].to_s.include?("Podman") }
      end

      # @return [Boolean] whether the daemon runs without root privileges
      def rootless?
        info["Rootless"] == true
      end

      # Stream events from the daemon as they happen.
      #
      # @param since [String, Integer, nil] where to start in the past
      # @param until_time [String, Integer, nil] where to stop
      # @param filters [Hash, nil] which events to report
      # @yieldparam event [Hash] one event
      # @return [void]
      #
      # @example
      #   client.system.events(filters: { "type" => ["container"] }) do |event|
      #     puts "#{event["Action"]} #{event.dig("Actor", "Attributes", "name")}"
      #   end
      def events(since: nil, until_time: nil, filters: nil, &block)
        raise ArgumentError, "events needs a block to yield to" unless block

        stream = Stream::JSONLines.new(&block)
        operations.system_events(
          since: since, until_: until_time, filters: filters
        ) { |chunk| stream << chunk }
        nil
      end

      # Check credentials against a registry.
      #
      # @param username [String] the account
      # @param password [String] its password or token
      # @param serveraddress [String, nil] the registry, or nil for Docker Hub
      # @return [Hash] the daemon's answer
      # @raise [Docker::API::Unauthorized] if the registry rejected them
      def authenticate(username:, password:, serveraddress: nil)
        operations.system_auth(
          body: {
            "username" => username, "password" => password,
            "serveraddress" => serveraddress || Auth::DOCKER_HUB_KEY
          }.compact
        ).json
      end
    end
  end
end
