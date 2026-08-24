# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Docker
  module API
    # Everything between "a socket exists" and "a Ruby value comes back".
    #
    # A connection owns request building, API version negotiation, error
    # mapping, streaming and hijack. It is immutable once built: there is no
    # setter for the URL or for credentials, which is what lets two connections
    # address two daemons in one process without interfering.
    class Connection
      # Endpoints that must not carry a version prefix, because they are how we
      # discover which version to use.
      UNVERSIONED = ["/_ping"].freeze

      # HTTP verbs mapped to the Net::HTTP request classes that implement them.
      VERBS = {
        get: Net::HTTP::Get,
        post: Net::HTTP::Post,
        put: Net::HTTP::Put,
        patch: Net::HTTP::Patch,
        delete: Net::HTTP::Delete,
        head: Net::HTTP::Head,
      }.freeze

      # @return [Docker::API::Transport::Base] the transport in use
      attr_reader :transport

      # @return [Logger, nil] where request metadata is logged, if anywhere
      attr_reader :logger

      # @param transport [Docker::API::Transport::Base] how to reach the daemon
      # @param api_version [String, Symbol] `:negotiate` to ask the daemon,
      #   a version string such as `"1.44"` to pin, or `:none` to send
      #   unprefixed paths
      # @param logger [Logger, nil] receives one debug line per request
      # @param read_timeout [Numeric] seconds to wait for response data
      # @param open_timeout [Numeric] seconds to wait for a connection
      def initialize(transport:, api_version: :negotiate, logger: nil,
        read_timeout: 60, open_timeout: 10)
        @transport = transport
        @configured_api_version = api_version
        @logger = logger
        @read_timeout = read_timeout
        @open_timeout = open_timeout
        @version_lock = Mutex.new
      end

      # The API version this connection prefixes its requests with.
      #
      # Negotiation happens once, lazily, on the first request that needs it.
      #
      # @return [String, nil] the version, or nil when versioning is disabled
      # @raise [Docker::API::VersionUnsupported] if the daemon is too old
      def api_version
        return @api_version if defined?(@api_version)

        @version_lock.synchronize do
          @api_version = resolve_api_version unless defined?(@api_version)
        end
        @api_version
      end

      # Ask the daemon whether it is alive. Never version-prefixed.
      #
      # @return [Docker::API::Response]
      def ping
        request(:get, "/_ping", operation: "ping")
      end

      # Send a request and interpret the answer.
      #
      # @param method [Symbol] one of :get, :post, :put, :patch, :delete, :head
      # @param path [String] the path, without a version prefix
      # @param query [Hash] query parameters in Ruby types
      # @param body [Hash, Array, String, IO, nil] the request body. Hashes and
      #   arrays are JSON-encoded; strings and IOs are sent as-is.
      # @param headers [Hash] additional request headers
      # @param expects [Array<Integer>] statuses that mean success
      # @param operation [String, Symbol, nil] names this call in errors and logs
      # @param content_type [String, nil] overrides the computed content type
      # @yieldparam chunk [String] successive body chunks, when streaming
      # @return [Docker::API::Response] with an empty body when streamed
      # @raise [Docker::API::Error] for any status outside `expects`
      def request(method, path, query: {}, body: nil, headers: {}, expects: [200],
        operation: nil, content_type: nil, &block)
        full_path = build_path(path, query)
        payload, computed_type = encode_body(body)
        request_headers = build_headers(headers, content_type || computed_type, payload)

        log(method, full_path, operation)

        response = perform(method, full_path, payload, request_headers, expects, &block)
        return response if expects.include?(response.status)

        raise Error.for(status: response.status, operation: operation, response: response)
      end

      # Take over the socket after an upgrade, for interactive exec and attach.
      #
      # This deliberately does not go through Net::HTTP. An interactive session
      # needs the socket itself, and `Net::BufferedIO` may already have read
      # ahead past the response headers. Rather than prise a buffered socket
      # back out of the stdlib -- the problem that produced docker-api's custom
      # Excon middleware -- this writes the request itself and hands back the
      # socket with nothing consumed but the response head.
      #
      # @param method [Symbol] the HTTP verb
      # @param path [String] the path, without a version prefix
      # @param query [Hash] query parameters
      # @param body [Hash, String, nil] the request body
      # @param headers [Hash] additional headers
      # @param operation [String, Symbol, nil] names this call in errors
      # @return [IO] the bidirectional socket, positioned at the stream body
      # @raise [Docker::API::Error] if the daemon refused to upgrade
      def hijack(method, path, query: {}, body: nil, headers: {}, operation: nil)
        io = transport.connect
        full_path = build_path(path, query)
        payload, computed_type = encode_body(body)

        write_raw_request(io, method, full_path, payload, headers, computed_type)
        status, response_headers = read_raw_response_head(io)

        unless [101, 200].include?(status)
          error_body = io.read.to_s
          io.close unless io.closed?
          raise Error.for(
            status: status, operation: operation,
            response: Response.new(status: status, headers: response_headers, body: error_body)
          )
        end

        io
      rescue Errno::EPIPE, Errno::ECONNRESET, EOFError => e
        io&.close unless io.nil? || io.closed?
        raise ConnectionError.new("the daemon closed the connection during #{operation}: #{e.message}")
      end

      # @return [String]
      def to_s
        "#<Docker::API::Connection transport=#{transport} api_version=#{
          defined?(@api_version) ? @api_version : "unnegotiated"}>"
      end
      alias_method :inspect, :to_s

      private

      # @return [String, nil]
      def resolve_api_version
        case @configured_api_version
        when :none then nil
        when :negotiate then negotiate_api_version
        else @configured_api_version.to_s.sub(/\Av/, "")
        end
      end

      # Ask the daemon what it speaks and meet it in the middle.
      #
      # Pinning to the daemon's version when it is older keeps us inside what
      # it understands; capping at what this gem vendors keeps us inside what
      # the generated layer knows how to ask for.
      #
      # @return [String]
      # @raise [Docker::API::VersionUnsupported]
      def negotiate_api_version
        response = ping
        daemon = response["api-version"]

        return MAX_API_VERSION if daemon.nil? || daemon.empty?

        if Gem::Version.new(daemon) < Gem::Version.new(MIN_API_VERSION)
          raise VersionUnsupported.new(
            "the daemon speaks Engine API v#{daemon}, but docker-api-ng requires " \
            "at least v#{MIN_API_VERSION}. Upgrade Docker, or pin an older release of this gem."
          )
        end

        [Gem::Version.new(daemon), Gem::Version.new(MAX_API_VERSION)].min.to_s
      end

      # @param path [String]
      # @param query [Hash]
      # @return [String]
      def build_path(path, query)
        prefix = if UNVERSIONED.include?(path) || api_version.nil?
                   ""
                 else
                   "/v#{api_version}"
                 end
        "#{prefix}#{path}#{Query.encode(query)}"
      end

      # Encode a body and work out what to call it.
      #
      # Every raw body in this API is an archive: a build context, a container
      # filesystem, an image tarball. Structured bodies are JSON. There is no
      # third case, so a body-bearing request never goes out unlabelled.
      #
      # That matters more than it looks. The daemon rejects the wrong content
      # type on its archive endpoints -- docker-api carries a middleware that
      # retries after parsing "Content-Type: application/json is not
      # supported. Should be application/x-tar" out of an error body -- and an
      # absent type is at the mercy of whatever the HTTP layer decides to
      # guess.
      #
      # @param body [Object]
      # @return [Array(String, IO, nil, String, nil)] the payload and its content type
      def encode_body(body)
        case body
        when nil then [nil, nil]
        when Hash, Array then [JSON.generate(body), "application/json"]
        else [body, "application/x-tar"]
        end
      end

      # @param headers [Hash]
      # @param content_type [String, nil]
      # @param payload [Object]
      # @return [Hash{String => String}]
      def build_headers(headers, content_type, payload)
        base = {
          "User-Agent" => "docker-api-ng/#{VERSION} (Ruby #{RUBY_VERSION})",
          "Accept" => "application/json",
        }
        base["Content-Type"] = content_type if content_type && payload
        base.merge(headers.transform_keys(&:to_s))
      end

      # @return [Docker::API::Response]
      def perform(method, full_path, payload, headers, expects, &block)
        klass = VERBS.fetch(method) { raise ArgumentError, "unsupported HTTP method: #{method.inspect}" }
        request = klass.new(full_path, headers)
        attach_payload(request, payload)

        session = Session.new(transport, read_timeout: @read_timeout, open_timeout: @open_timeout)
        result = nil

        session.start do |http|
          http.request(request) do |raw|
            status = raw.code.to_i
            result = if block && expects.include?(status)
                       raw.read_body { |chunk| block.call(chunk) }
                       Response.new(status: status, headers: raw.to_hash, body: nil)
                     else
                       Response.new(status: status, headers: raw.to_hash, body: raw.read_body)
                     end
          end
        end

        result
      # Net::OpenTimeout, Net::ReadTimeout and Net::WriteTimeout all descend
      # from Timeout::Error, so naming them individually would only shadow it.
      rescue Timeout::Error => e
        raise TimeoutError.new("#{transport} did not answer in time: #{e.class}: #{e.message}")
      # EOFError is an IOError, so listing it separately would only shadow it.
      rescue Net::HTTPBadResponse, Net::ProtocolError, IOError,
             SystemCallError, SocketError, OpenSSL::SSL::SSLError => e
        raise ConnectionError.new("#{transport} failed mid-request: #{e.class}: #{e.message}")
      end

      # @return [void]
      def attach_payload(request, payload)
        case payload
        when nil then nil
        when IO, StringIO
          request.body_stream = payload
          request["Transfer-Encoding"] = "chunked"
        else
          request.body = payload
        end
      end

      # @return [void]
      def write_raw_request(io, method, full_path, payload, headers, content_type)
        lines = ["#{method.to_s.upcase} #{full_path} HTTP/1.1"]
        head = {
          "Host" => transport.host_header,
          "User-Agent" => "docker-api-ng/#{VERSION} (Ruby #{RUBY_VERSION})",
          "Connection" => "Upgrade",
          "Upgrade" => "tcp",
          "Content-Length" => (payload ? payload.bytesize : 0).to_s,
        }
        head["Content-Type"] = content_type if content_type && payload
        head.merge!(headers.transform_keys(&:to_s))

        head.each { |key, value| lines << "#{key}: #{value}" }
        io.write("#{lines.join("\r\n")}\r\n\r\n")
        io.write(payload) if payload
        io.flush if io.respond_to?(:flush)
      end

      # @return [Array(Integer, Hash)]
      def read_raw_response_head(io)
        status_line = io.gets
        raise ConnectionError.new("the daemon closed the connection before answering") if status_line.nil?

        status = status_line[%r{\AHTTP/\d\.\d\s+(\d+)}, 1].to_i
        headers = {}
        while (line = io.gets)
          line = line.chomp
          break if line.empty?

          key, _, value = line.partition(":")
          headers[key.strip.downcase] = value.strip
        end
        [status, headers]
      end

      # @return [void]
      def log(method, full_path, operation)
        return unless logger

        logger.debug { "docker-api-ng #{operation || "request"} #{method.to_s.upcase} #{full_path}" }
      end
    end
  end
end
