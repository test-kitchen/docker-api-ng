# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Docker
  module API
    # A connection to one Docker daemon, and the way in to everything else.
    #
    # A client owns its configuration and its connection. There is no global
    # state behind it: two clients addressing two daemons share nothing, so a
    # process can talk to a local daemon and a remote builder at the same time
    # without either one noticing.
    #
    # @example The local daemon
    #   client = Docker::API::Client.new
    #   client.system.info["ServerVersion"]
    #
    # @example A remote daemon over TLS
    #   client = Docker::API::Client.new(
    #     url: "tcp://build.internal:2376",
    #     tls: { ca_file: "ca.pem", cert_file: "cert.pem", key_file: "key.pem" }
    #   )
    #
    # @example Reaching an endpoint with no ergonomic wrapper
    #   client.operations.container_prune(filters: { "until" => ["24h"] })
    class Client
      # @return [Docker::API::Config] this client's frozen configuration
      attr_reader :config

      # @return [Docker::API::Connection] the connection in use
      attr_reader :connection

      # @param url [String, nil] the daemon URL. Falls back to `DOCKER_HOST`,
      #   then to the platform's default socket.
      # @param tls [Hash, nil] TLS material: `:ca_file`, `:cert_file`,
      #   `:key_file`, `:verify`. Falls back to `DOCKER_CERT_PATH`.
      # @param api_version [String, Symbol] `:negotiate` to ask the daemon what
      #   it speaks, a version such as `"1.44"` to pin, or `:none` to send
      #   unprefixed paths
      # @param logger [Logger, nil] receives one debug line per request
      # @param read_timeout [Numeric] seconds to wait for response data
      # @param open_timeout [Numeric] seconds to wait for a connection
      # @param transport [Docker::API::Transport::Base, nil] a transport to use
      #   instead of building one from the URL. Mainly for tests, where
      #   {Docker::API::Transport::Fake} stands in for a daemon.
      # @param env [Hash] the environment to resolve defaults from
      def initialize(url: nil, tls: nil, api_version: :negotiate, logger: nil,
        read_timeout: 60, open_timeout: 10, transport: nil, env: ENV)
        @config = Config.from_env(
          env,
          url: url, api_version: api_version,
          read_timeout: read_timeout, open_timeout: open_timeout,
          **(tls.nil? ? {} : { tls: tls })
        )

        @connection = Connection.new(
          transport: transport || Transport.for(
            url: config.url, tls: config.tls, open_timeout: config.open_timeout
          ),
          api_version: config.api_version,
          logger: logger,
          read_timeout: config.read_timeout,
          open_timeout: config.open_timeout
        )
      end

      # Every Engine API operation, one method each.
      #
      # This is public API rather than an escape hatch. The ergonomic
      # collections below cover what most code needs; anything they have not
      # grown sugar for is reachable here, fully documented and typed, with no
      # loss of capability.
      #
      # @return [Docker::API::Operations]
      def operations
        @operations ||= Operations.new(connection)
      end

      # @return [Docker::API::Containers]
      def containers
        @containers ||= Containers.new(self)
      end

      # @return [Docker::API::Images]
      def images
        @images ||= Images.new(self)
      end

      # @return [Docker::API::Networks]
      def networks
        @networks ||= Networks.new(self)
      end

      # @return [Docker::API::Volumes]
      def volumes
        @volumes ||= Volumes.new(self)
      end

      # @return [Docker::API::System]
      def system
        @system ||= System.new(self)
      end

      # @return [String, nil] the negotiated Engine API version
      def api_version
        connection.api_version
      end

      # @return [String]
      def to_s
        "#<Docker::API::Client url=#{config.url}>"
      end
      alias_method :inspect, :to_s
    end
  end
end
