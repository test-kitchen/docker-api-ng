# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Docker
  module API
    module Transport
      # A daemon reached over TLS, as `DOCKER_CERT_PATH` configures.
      #
      # The handshake happens here rather than in Net::HTTP. That is deliberate:
      # the layer above receives an already-encrypted socket and does not need
      # to know whether TLS is in play, which keeps one code path for every
      # transport.
      class Tls < Tcp
        # @param host [String] the host to dial
        # @param port [Integer] the port to dial
        # @param ca_file [String, nil] path to the CA bundle
        # @param cert_file [String, nil] path to the client certificate
        # @param key_file [String, nil] path to the client key
        # @param verify [Boolean] whether to verify the daemon's certificate
        # @param open_timeout [Numeric] seconds to wait for the connection
        def initialize(host:, port:, ca_file: nil, cert_file: nil, key_file: nil,
          verify: true, open_timeout: 10)
          super(host: host, port: port, open_timeout: open_timeout)
          @ca_file = ca_file
          @cert_file = cert_file
          @key_file = key_file
          @verify = verify
        end

        # @return [OpenSSL::SSL::SSLSocket] a connected, handshaken socket
        # @raise [Docker::API::ConnectionError]
        def connect
          dial("https://#{host}:#{port}") do
            socket = OpenSSL::SSL::SSLSocket.new(super_socket, ssl_context)
            socket.hostname = host # SNI, which some proxies in front of a daemon require
            socket.sync_close = true
            socket.connect
            socket
          end
        end

        # @return [String]
        def to_s
          "#<Docker::API::Transport::Tls host=#{host} port=#{port} verify=#{@verify}>"
        end
        alias_method :inspect, :to_s

        private

        # @return [IO] the underlying TCP socket
        def super_socket
          Socket.tcp(host, port, connect_timeout: @open_timeout)
        end

        # @return [OpenSSL::SSL::SSLContext]
        def ssl_context
          context = OpenSSL::SSL::SSLContext.new
          context.min_version = OpenSSL::SSL::TLS1_2_VERSION
          context.verify_mode = @verify ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
          context.ca_file = @ca_file if @ca_file
          if @cert_file && @key_file
            context.cert = OpenSSL::X509::Certificate.new(File.read(@cert_file))
            context.key = OpenSSL::PKey.read(File.read(@key_file))
          end
          context
        end
      end
    end
  end
end
