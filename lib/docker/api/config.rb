# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

require "rbconfig" unless defined?(RbConfig)

module Docker
  module API
    # Where the daemon is and how to reach it, resolved once and then frozen.
    #
    # Frozen is the point. The docker-api gem exposes `Docker.url=` and
    # `Docker.creds=` as process-global setters, so a second caller silently
    # inherits -- or clobbers -- the first caller's daemon. Configuration here
    # is a value: two clients hold two of them and cannot interfere.
    class Config
      # Where Docker listens by default on Linux and macOS.
      DEFAULT_UNIX_SOCKET = "unix:///var/run/docker.sock"

      # Where Docker Desktop for Windows listens by default.
      DEFAULT_WINDOWS_PIPE = "npipe:////./pipe/docker_engine"

      # @return [String] the daemon URL
      attr_reader :url

      # @return [Hash] TLS material, empty when TLS is not in use
      attr_reader :tls

      # @return [String, Symbol] `:negotiate`, `:none`, or a pinned version
      attr_reader :api_version

      # @return [Numeric] seconds to wait for response data
      attr_reader :read_timeout

      # @return [Numeric] seconds to wait for a connection
      attr_reader :open_timeout

      # @param url [String, nil] the daemon URL
      # @param tls [Hash, nil] TLS material
      # @param api_version [String, Symbol] version handling
      # @param read_timeout [Numeric] seconds
      # @param open_timeout [Numeric] seconds
      def initialize(url: nil, tls: nil, api_version: :negotiate,
        read_timeout: 60, open_timeout: 10)
        @url = url || self.class.default_url
        @tls = (tls || {}).freeze
        @api_version = api_version
        @read_timeout = read_timeout
        @open_timeout = open_timeout
        freeze
      end

      # Resolve configuration the way the Docker CLI does.
      #
      # @param env [Hash] the environment to read, injectable for tests
      # @return [Docker::API::Config]
      #
      # @example
      #   Config.from_env("DOCKER_HOST" => "tcp://build:2376",
      #                   "DOCKER_CERT_PATH" => "/certs",
      #                   "DOCKER_TLS_VERIFY" => "1")
      def self.from_env(env = ENV, **overrides)
        # Ruby permits non-Symbol keys in a **kwargs splat, so
        # `from_env("DOCKER_HOST" => "tcp://x")` puts the variable in overrides
        # and quietly reads the real environment instead. Saying so is much
        # kinder than resolving the wrong daemon and never mentioning it.
        stray = overrides.keys.grep(String)
        unless stray.empty?
          raise ArgumentError,
            "from_env takes the environment as its first argument: " \
            "from_env({ #{stray.first.inspect} => ... }). Got #{stray.inspect} as options."
        end

        url = overrides[:url] || env["DOCKER_HOST"] || env["DOCKER_URL"] || default_url
        tls = overrides.key?(:tls) ? overrides[:tls] : tls_from_env(env)

        new(
          url: url,
          tls: tls,
          api_version: overrides.fetch(:api_version, env["DOCKER_API_VERSION"] || :negotiate),
          read_timeout: overrides.fetch(:read_timeout, 60),
          open_timeout: overrides.fetch(:open_timeout, 10)
        )
      end

      # @return [String] the platform's default daemon URL
      def self.default_url
        windows? ? DEFAULT_WINDOWS_PIPE : DEFAULT_UNIX_SOCKET
      end

      # @return [Boolean]
      def self.windows?
        RbConfig::CONFIG["host_os"].match?(/mswin|mingw|cygwin/)
      end

      # Build TLS material from `DOCKER_CERT_PATH`, which is the only way the
      # CLI expresses it.
      #
      # `DOCKER_TLS_VERIFY` is a presence flag rather than a boolean: the CLI
      # treats an empty value as "off", so an exported-but-empty variable does
      # not silently start verifying.
      #
      # @param env [Hash]
      # @return [Hash]
      def self.tls_from_env(env)
        cert_path = env["DOCKER_CERT_PATH"]
        return {} if cert_path.nil? || cert_path.empty?

        {
          ca_file: File.join(cert_path, "ca.pem"),
          cert_file: File.join(cert_path, "cert.pem"),
          key_file: File.join(cert_path, "key.pem"),
          verify: !env["DOCKER_TLS_VERIFY"].to_s.empty?,
        }
      end
      private_class_method :tls_from_env

      # @return [String]
      def to_s
        "#<Docker::API::Config url=#{url} tls=#{tls.empty? ? "none" : "configured"} " \
          "api_version=#{api_version}>"
      end
      alias_method :inspect, :to_s
    end
  end
end
