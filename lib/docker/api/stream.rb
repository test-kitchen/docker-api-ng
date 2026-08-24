# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Docker
  module API
    # Decoders for the three wire formats the Engine API streams in.
    #
    # All three are stateful accumulators, and that is the important part. HTTP
    # hands us chunks at byte boundaries that have nothing to do with Docker's
    # framing: a frame header can be split across two chunks and a JSON object
    # can be split mid-string. A decoder that assumes a chunk is a message
    # passes its tests and then interleaves garbage in production, which is
    # precisely the bug class that makes `exec` output untrustworthy.
    module Stream
      # Docker's multiplexed frame header is eight bytes: a stream id, three
      # bytes of padding, then a big-endian payload length.
      HEADER_SIZE = 8

      # Stream ids as they appear in the first header byte.
      STREAM_NAMES = { 0 => :stdin, 1 => :stdout, 2 => :stderr }.freeze

      # Splits Docker's multiplexed stdout/stderr framing back into named
      # streams.
      #
      # Used whenever a container was created without a TTY. With a TTY the
      # daemon sends unframed bytes instead, which is what {Raw} is for.
      #
      # @example
      #   demux = Stream::Demultiplexer.new { |name, chunk| $stdout << chunk if name == :stdout }
      #   demux << first_chunk << second_chunk
      class Demultiplexer
        # @yieldparam name [Symbol] one of :stdin, :stdout, :stderr
        # @yieldparam chunk [String] the payload, in UTF-8
        def initialize(&block)
          raise ArgumentError, "Demultiplexer needs a block to yield frames to" unless block

          @block = block
          @buffer = +"".b
        end

        # Feed bytes in. Complete frames are yielded; a partial frame is held
        # until the rest of it arrives.
        #
        # @param chunk [String] any number of bytes, at any boundary
        # @return [self]
        def <<(chunk)
          @buffer << chunk.to_s.b
          emit_frames
          self
        end

        # @return [Boolean] whether bytes are being held back for a partial frame
        def pending?
          !@buffer.empty?
        end

        private

        # @return [void]
        def emit_frames
          loop do
            break if @buffer.bytesize < HEADER_SIZE

            length = @buffer.byteslice(4, 4).unpack1("N")
            break if @buffer.bytesize < HEADER_SIZE + length

            stream = STREAM_NAMES.fetch(@buffer.getbyte(0), :unknown)
            payload = @buffer.byteslice(HEADER_SIZE, length)
            @buffer = @buffer.byteslice(HEADER_SIZE + length..) || +"".b

            @block.call(stream, payload.force_encoding(Encoding::UTF_8))
          end
        end
      end

      # Parses the newline-delimited JSON that pull, push, build and /events
      # stream their progress in.
      #
      # @example
      #   lines = Stream::JSONLines.new { |event| puts event["status"] }
      #   lines << chunk
      class JSONLines
        # @yieldparam object [Hash] one decoded JSON document
        def initialize(&block)
          raise ArgumentError, "JSONLines needs a block to yield objects to" unless block

          @block = block
          @buffer = +""
        end

        # @param chunk [String] any number of bytes, at any boundary
        # @return [self]
        # @raise [Docker::API::StreamError] if a complete line is not valid JSON
        def <<(chunk)
          @buffer << chunk.to_s
          emit_lines
          self
        end

        private

        # @return [void]
        def emit_lines
          while (index = @buffer.index("\n"))
            line = @buffer.slice!(0, index + 1).strip
            next if line.empty?

            @block.call(parse(line))
          end
        end

        # @param line [String]
        # @return [Hash]
        def parse(line)
          JSON.parse(line)
        rescue JSON::ParserError => e
          raise StreamError.new("the daemon sent a line that is not valid JSON: #{e.message}")
        end
      end

      # Passes bytes straight through, for TTY-enabled streams and for raw
      # archive downloads where there is no framing to undo.
      class Raw
        # @yieldparam chunk [String]
        def initialize(&block)
          raise ArgumentError, "Raw needs a block to yield chunks to" unless block

          @block = block
        end

        # @param chunk [String]
        # @return [self]
        def <<(chunk)
          @block.call(chunk)
          self
        end
      end
    end
  end
end
