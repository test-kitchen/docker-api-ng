# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Docker
  module API
    module Transport
      # A daemon reached over a unix domain socket, which is how Docker is
      # reached on Linux and macOS by default.
      class Unix < Base
        # @return [String] the socket path
        attr_reader :path

        # @param path [String] the socket path, e.g. "/var/run/docker.sock"
        def initialize(path:)
          super()
          @path = path
        end

        # @return [IO] a connected unix socket
        # @raise [Docker::API::ConnectionError]
        def connect
          dial("unix://#{path}") { UNIXSocket.new(path) }
        end

        # @return [String]
        def to_s
          "#<Docker::API::Transport::Unix path=#{path}>"
        end
        alias_method :inspect, :to_s
      end
    end
  end
end
