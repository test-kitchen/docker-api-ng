# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

require "base64" unless defined?(Base64)
require "English"

module Docker
  module API
    # Registry credentials, resolved per call.
    #
    # There is no credential store on this module and no way to set one
    # globally. Credentials are looked up for the registry a particular request
    # is talking to and travel on that request as `X-Registry-Auth`, so pulling
    # from two registries in one process needs no coordination.
    module Auth
      # Docker Hub's canonical auth key, which is not the hostname you pull from.
      DOCKER_HUB_KEY = "https://index.docker.io/v1/"

      module_function

      # Find credentials for a registry and encode them for the daemon.
      #
      # Every failure mode here is soft. A missing config file, an unreadable
      # one, or a credential helper that is not installed all mean "no
      # credentials", because anonymous pulls of public images must keep
      # working on a machine that has never run `docker login`.
      #
      # @param registry [String, nil] a registry hostname, or nil for Docker Hub
      # @param config_path [String, nil] path to config.json, for tests
      # @return [String, nil] a base64 `X-Registry-Auth` value, or nil
      def resolve(registry = nil, config_path: nil)
        key = registry_key(registry)
        config = read_config(config_path)
        return nil if config.nil?

        credentials = from_helper(config, key) || from_auths(config, key)
        return nil if credentials.nil?

        encode(credentials)
      end

      # Encode a credential hash the way the daemon expects it: base64url of a
      # JSON document, in a header.
      #
      # @param credentials [Hash] with :username, :password, :serveraddress
      # @return [String]
      def encode(credentials)
        Base64.urlsafe_encode64(JSON.generate(credentials)).delete("\n")
      end

      # Docker Hub is stored under a URL key rather than its hostname, and an
      # empty registry means Hub. Everything else is keyed by hostname.
      #
      # @param registry [String, nil]
      # @return [String]
      def registry_key(registry)
        return DOCKER_HUB_KEY if registry.nil? || registry.empty?
        return DOCKER_HUB_KEY if ["docker.io", "index.docker.io", "registry-1.docker.io"].include?(registry)

        registry
      end

      # @param path [String, nil]
      # @return [Hash, nil]
      def read_config(path)
        path ||= File.join(Dir.home, ".docker", "config.json")
        return nil unless File.readable?(path)

        JSON.parse(File.read(path))
      rescue JSON::ParserError, SystemCallError, ArgumentError
        nil
      end

      # @param config [Hash]
      # @param key [String]
      # @return [Hash, nil]
      def from_auths(config, key)
        entry = config.dig("auths", key)
        return nil if entry.nil?

        if entry["auth"] && !entry["auth"].empty?
          username, _, password = Base64.decode64(entry["auth"]).partition(":")
          return { username: username, password: password, serveraddress: key }
        end

        return nil if entry["username"].nil?

        { username: entry["username"], password: entry["password"], serveraddress: key }
      end

      # A helper named for this specific registry wins over the catch-all
      # store, which is how `credHelpers` is specified to behave.
      #
      # @param config [Hash]
      # @param key [String]
      # @return [Hash, nil]
      def from_helper(config, key)
        helper = config.dig("credHelpers", key) ||
          config.dig("credHelpers", URI(key).host.to_s) ||
          config["credsStore"]
        return nil if helper.nil? || helper.empty?

        run_helper(helper, key)
      rescue URI::InvalidURIError
        nil
      end

      # Invoke `docker-credential-<helper> get`, which reads the registry on
      # stdin and writes JSON on stdout.
      #
      # The command is passed as an argument array, never a shell string, so a
      # helper name from a config file cannot become a shell injection.
      #
      # @param helper [String] the helper's short name
      # @param key [String] the registry to ask about
      # @return [Hash, nil]
      def run_helper(helper, key)
        output = IO.popen(["docker-credential-#{helper}", "get"], "r+") do |io|
          io.write(key)
          io.close_write
          io.read
        end
        return nil unless $CHILD_STATUS.nil? || $CHILD_STATUS.success?

        parsed = JSON.parse(output.to_s)
        secret = parsed["Secret"]
        return nil if secret.nil? || secret.empty?

        # A username of <token> is the helper's way of saying the secret is an
        # identity token rather than a password.
        if parsed["Username"] == "<token>"
          { identitytoken: secret, serveraddress: parsed["ServerURL"] || key }
        else
          { username: parsed["Username"], password: secret,
            serveraddress: parsed["ServerURL"] || key }
        end
      rescue Errno::ENOENT, Errno::EACCES, JSON::ParserError, IOError
        nil
      end
    end
  end
end
