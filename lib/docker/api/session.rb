# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Docker
  module API
    # A Net::HTTP that connects through a {Docker::API::Transport} rather than
    # by dialling a hostname itself.
    #
    # Overriding `#connect` is the whole trick, and it is what makes a
    # dependency-free client practical: the stdlib keeps doing the tedious,
    # well-tested parts -- chunked transfer decoding, keep-alive, header
    # parsing, 100-continue -- while we retain ownership of the socket. That
    # ownership is what unix sockets, TLS and Windows named pipes all need, and
    # it is why none of them requires an HTTP library that knows about Docker.
    #
    # @api private
    class Session < Net::HTTP
      class << self
        # Net::HTTP.new is not a plain allocator: it resolves proxy settings
        # and then re-dispatches to Class#new with its own positional
        # arguments, which do not match ours. A session connects through a
        # transport and never proxies, so that work is not merely unnecessary,
        # it actively gets in the way.
        #
        # @param transport [Docker::API::Transport::Base] the transport to dial through
        # @param read_timeout [Numeric] seconds to wait for response data
        # @param open_timeout [Numeric] seconds to wait for the connection
        # @return [Docker::API::Session]
        def new(transport, read_timeout: 60, open_timeout: 10)
          allocate.tap do |session|
            session.send(:initialize, transport,
              read_timeout: read_timeout, open_timeout: open_timeout)
          end
        end
      end

      # @param transport [Docker::API::Transport::Base] the transport to dial through
      # @param read_timeout [Numeric] seconds to wait for response data
      # @param open_timeout [Numeric] seconds to wait for the connection
      def initialize(transport, read_timeout: 60, open_timeout: 10)
        super(transport.host_header, 80)
        @transport = transport
        self.read_timeout = read_timeout
        self.open_timeout = open_timeout
      end

      private

      # Use the transport's socket instead of opening one.
      #
      # When TLS is in play the transport has already completed the handshake,
      # so `use_ssl` stays false and Net::HTTP never tries to negotiate a
      # second session over the top of the first.
      #
      # @return [void]
      def connect
        @socket = Net::BufferedIO.new(
          @transport.connect,
          read_timeout: @read_timeout,
          write_timeout: @write_timeout,
          continue_timeout: @continue_timeout,
          debug_output: @debug_output
        )
        on_connect
      end
    end
  end
end
