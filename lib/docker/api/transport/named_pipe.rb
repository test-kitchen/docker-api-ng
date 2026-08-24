# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Docker
  module API
    module Transport
      # A daemon reached over a Windows named pipe, which is how Docker Desktop
      # for Windows exposes the Engine API by default.
      #
      # Windows named pipes present as files, so a binary-mode File is a
      # bidirectional stream that behaves closely enough to a socket for the
      # layer above. This is the transport the docker-api gem never grew, which
      # is why kitchen-dokken carries a standing TODO about Windows support.
      class NamedPipe < Base
        # The pipe Docker Desktop for Windows publishes by default.
        DEFAULT_PIPE = "//./pipe/docker_engine"

        # @return [String] the pipe path
        attr_reader :path

        # @param path [String] the pipe path
        def initialize(path: DEFAULT_PIPE)
          super()
          @path = path
        end

        # @return [IO] the opened pipe
        # @raise [Docker::API::ConnectionError]
        def connect
          dial("npipe://#{path}") do
            pipe = File.open(windows_path, "r+b")
            pipe.sync = true
            pipe
          end
        end

        # @return [String]
        def to_s
          "#<Docker::API::Transport::NamedPipe path=#{path}>"
        end
        alias_method :inspect, :to_s

        private

        # Accept both the forward-slash form that appears in DOCKER_HOST and
        # the backslash form Windows itself uses, rather than making callers
        # care which one they happen to have.
        #
        # @return [String]
        def windows_path
          path.tr("/", "\\")
        end
      end
    end
  end
end
