# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Docker
  module API
    # Transports know how to reach a daemon, and nothing else.
    #
    # Every transport answers {Base#connect} with a connected IO. That single
    # responsibility is what lets the same connection code drive a unix socket
    # in development, TLS in CI and a Windows named pipe on a laptop.
    module Transport
      # Build the transport a Docker host URL calls for.
      #
      # @param url [String] a Docker host URL. Understands `unix://`, `tcp://`,
      #   `http://`, `https://`, `npipe://`, and a bare path (taken as a unix
      #   socket), matching what `DOCKER_HOST` may contain.
      # @param tls [Hash, nil] TLS material: `:ca_file`, `:cert_file`,
      #   `:key_file`, `:verify`. Any of these upgrades a `tcp://` URL to TLS.
      # @param open_timeout [Numeric] seconds to wait for a connection
      # @return [Docker::API::Transport::Base]
      # @raise [Docker::API::ConnectionError] if the scheme is not one we speak
      #
      # @example
      #   Transport.for(url: "unix:///var/run/docker.sock")
      #   Transport.for(url: "tcp://build:2376", tls: { ca_file: "ca.pem" })
      def self.for(url:, tls: nil, open_timeout: 10)
        scheme, rest = split(url.to_s)
        tls = nil if tls.respond_to?(:empty?) && tls.empty?

        case scheme
        when "unix"
          Unix.new(path: rest)
        when "npipe"
          NamedPipe.new(path: rest)
        when "https"
          tcp_transport(rest, tls || {}, open_timeout, secure: true)
        when "tcp", "http"
          tcp_transport(rest, tls, open_timeout, secure: !tls.nil?)
        else
          raise ConnectionError.new(
            "cannot reach a Docker daemon over '#{scheme}' (from #{url.inspect}); " \
            "expected one of unix, tcp, http, https or npipe"
          )
        end
      end

      # Split a host URL into a scheme and the remainder.
      #
      # Hand-parsed rather than handed to URI, because `unix:///var/run/x.sock`
      # and `npipe:////./pipe/docker_engine` are not URLs that URI's generic
      # parser handles the way Docker means them.
      #
      # @param url [String]
      # @return [Array(String, String)] the scheme and the remainder
      # @api private
      def self.split(url)
        if (match = url.match(%r{\A(?<scheme>[a-z][a-z0-9+.-]*)://(?<rest>.*)\z}i))
          scheme = match[:scheme].downcase
          rest = match[:rest]
          # unix and npipe carry a path, and the leading slash is part of it.
          rest = "/#{rest}" if %w{unix npipe}.include?(scheme) && !rest.start_with?("/")
          [scheme, rest]
        elsif url.start_with?("/", "\\") || url.empty?
          # A bare path is what a daemon on a unix socket looks like.
          ["unix", url.empty? ? "/var/run/docker.sock" : url]
        else
          ["tcp", url]
        end
      end
      private_class_method :split

      # @param authority [String] "host:port" or "host"
      # @param tls [Hash, nil] TLS material
      # @param open_timeout [Numeric]
      # @param secure [Boolean]
      # @return [Docker::API::Transport::Tcp, Docker::API::Transport::Tls]
      # @api private
      def self.tcp_transport(authority, tls, open_timeout, secure:)
        host, port = split_authority(authority, secure: secure)

        return Tcp.new(host: host, port: port, open_timeout: open_timeout) unless secure

        tls ||= {}
        Tls.new(
          host: host, port: port, open_timeout: open_timeout,
          ca_file: tls[:ca_file], cert_file: tls[:cert_file], key_file: tls[:key_file],
          verify: tls.fetch(:verify, true)
        )
      end
      private_class_method :tcp_transport

      # @param authority [String]
      # @param secure [Boolean]
      # @return [Array(String, Integer)]
      # @api private
      def self.split_authority(authority, secure:)
        authority = authority.sub(%r{/.*\z}, "")
        default_port = secure ? 2376 : 2375
        # `tcp://` with nothing after it means localhost, which is what the
        # Docker CLI does with a bare scheme.
        return ["localhost", default_port] if authority.empty?

        host, _, port = authority.rpartition(":")
        return [authority, default_port] if host.empty?

        [host, port.empty? ? default_port : Integer(port)]
      end
      private_class_method :split_authority
    end
  end
end
