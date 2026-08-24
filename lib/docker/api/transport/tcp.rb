# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Docker
  module API
    module Transport
      # A daemon reached over plain TCP. Unencrypted, so appropriate only on a
      # trusted network or a loopback address.
      class Tcp < Base
        # @return [String] the host
        attr_reader :host

        # @return [Integer] the port
        attr_reader :port

        # @param host [String] the host to dial
        # @param port [Integer] the port to dial
        # @param open_timeout [Numeric] seconds to wait for the connection
        def initialize(host:, port:, open_timeout: 10)
          super()
          @host = host
          @port = Integer(port)
          @open_timeout = open_timeout
        end

        # @return [IO] a connected TCP socket
        # @raise [Docker::API::ConnectionError]
        def connect
          dial("tcp://#{host}:#{port}") do
            Socket.tcp(host, port, connect_timeout: @open_timeout)
          end
        end

        # @return [String]
        def host_header
          "#{host}:#{port}"
        end

        # @return [String]
        def to_s
          "#<Docker::API::Transport::Tcp host=#{host} port=#{port}>"
        end
        alias_method :inspect, :to_s
      end
    end
  end
end
