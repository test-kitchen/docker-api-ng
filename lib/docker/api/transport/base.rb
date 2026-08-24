# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Docker
  module API
    module Transport
      # The contract every transport honours: make a socket, say what Host
      # header requests over it should carry, and describe yourself for logs.
      #
      # Transports know how to dial, and nothing else. Keeping them this narrow
      # is what makes the layer above testable -- {Docker::API::Transport::Fake}
      # is a drop-in because there is so little to stand in for.
      #
      # @abstract Subclass and implement {#connect}.
      class Base
        # Open a connection.
        #
        # @return [IO] a connected, readable and writable socket
        # @raise [Docker::API::ConnectionError] if the endpoint cannot be reached
        def connect
          raise NotImplementedError, "#{self.class} must implement #connect"
        end

        # The daemon does not route on Host, but HTTP/1.1 requires the header
        # and some proxies in front of a daemon do care.
        #
        # @return [String]
        def host_header
          "localhost"
        end

        # @return [String] a description safe to put in a log line
        def to_s
          "#<#{self.class.name}>"
        end
        alias_method :inspect, :to_s

        private

        # Run a block that dials a socket, converting every way the operating
        # system and OpenSSL report failure into one gem error.
        #
        # This is the boundary that stops `Errno::ECONNREFUSED` from appearing
        # in a caller's rescue clause and coupling them to our plumbing.
        #
        # @param endpoint [String] what we were trying to reach, for the message
        # @yieldreturn [IO]
        # @return [IO]
        # @raise [Docker::API::ConnectionError]
        def dial(endpoint)
          yield
        rescue SystemCallError, SocketError, IOError, OpenSSL::SSL::SSLError, Timeout::Error => e
          raise ConnectionError.new(
            "could not connect to the Docker daemon at #{endpoint}: #{e.class}: #{e.message}"
          )
        end
      end
    end
  end
end
