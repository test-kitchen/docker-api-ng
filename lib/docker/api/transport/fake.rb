# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Docker
  module API
    module Transport
      # A scripted daemon for tests, served over a real socket pair.
      #
      # The socket is genuine on purpose. `Net::BufferedIO` calls
      # `read_nonblock`, `write` and `to_io` on whatever it is handed, and a
      # StringIO does not honour that contract. Faking it produces tests that
      # pass against a double the production code could never actually drive.
      # `Socket.pair` gives real socket semantics with no network, so the
      # connection layer is exercised exactly as it runs against a daemon --
      # including chunked bodies, keep-alive and connection upgrades.
      #
      # @example Scripting one response
      #   fake = Docker::API::Transport::Fake.new([
      #     "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nok",
      #   ])
      #   client = Docker::API::Client.new(transport: fake, api_version: "1.55")
      #   client.system.info
      #   fake.requests.first #=> "GET /v1.55/info HTTP/1.1\r\n..."
      class Fake < Base
        # @return [Array<String>] raw request bytes, in the order received
        attr_reader :requests

        # @param responses [Array<String>] raw HTTP responses to serve, in order
        def initialize(responses = [])
          super()
          @responses = Array(responses).dup
          @requests = []
          @mutex = Mutex.new
          @threads = []
        end

        # Add another scripted response.
        #
        # @param response [String] raw HTTP response bytes
        # @return [self]
        def <<(response)
          @mutex.synchronize { @responses << response }
          self
        end

        # @return [IO] the client end of a socket pair with a server behind it
        def connect
          ours, theirs = Socket.pair(:UNIX, :STREAM)
          thread = Thread.new { serve(theirs) }
          thread.report_on_exception = false
          @threads << thread
          ours
        end

        # Wait for the scripted server to finish, so assertions about recorded
        # requests do not race the thread that records them.
        #
        # @return [void]
        def finish
          @threads.each { |thread| thread.join(2) }
          self
        end

        # @return [String]
        def to_s
          "#<Docker::API::Transport::Fake scripted=#{@responses.size}>"
        end
        alias_method :inspect, :to_s

        private

        # Serve requests until the client goes away or the script runs out.
        #
        # Hanging up once the last scripted response has been written is what
        # lets a client that reads to end-of-stream finish. A server that
        # politely waited for another request would leave every such read
        # blocked forever, which is a hang rather than a failure and therefore
        # far more annoying to diagnose.
        #
        # @param io [IO] the server end of the pair
        # @return [void]
        def serve(io)
          loop do
            request = read_request(io)
            break if request.nil?

            @mutex.synchronize { @requests << request }
            response, remaining = @mutex.synchronize { [@responses.shift, @responses.size] }
            break if response.nil?

            io.write(response)
            break if remaining == 0
          end
        rescue IOError, SystemCallError
          nil
        ensure
          begin
            io.close unless io.closed?
          rescue IOError, SystemCallError
            nil
          end
        end

        # Read one complete HTTP request: the head, then the body, however
        # the client chose to frame it.
        #
        # Chunked bodies matter here rather than being pedantry. A build
        # context is streamed from an IO, so Net::HTTP sends it chunked with no
        # Content-Length. A fake that stops after the head leaves the body in
        # the socket, reads it as if it were the next request, and quietly
        # consumes the response scripted for the call after this one.
        #
        # @param io [IO] the server end of the pair
        # @return [String, nil] raw request bytes, or nil at end of stream
        def read_request(io)
          head = +""
          until head.end_with?("\r\n\r\n")
            line = io.gets
            return nil if line.nil?

            head << line
          end

          return head + read_chunked_body(io) if head.match?(/^Transfer-Encoding:\s*chunked/i)

          length = head[/^Content-Length:\s*(\d+)/i, 1]
          return head if length.nil?

          head + io.read(Integer(length)).to_s
        end

        # @param io [IO] the server end of the pair
        # @return [String] the decoded body
        def read_chunked_body(io)
          body = +""
          loop do
            size_line = io.gets
            break if size_line.nil?

            size = size_line.strip.split(";").first.to_i(16)
            break if size == 0

            body << io.read(size).to_s
            io.read(2) # the CRLF that terminates the chunk
          end
          io.gets # the blank line after the terminating chunk
          body
        end
      end
    end
  end
end
