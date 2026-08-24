# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

require "digest" unless defined?(Digest)

module Docker
  module API
    # Docker's context store, which is where the CLI keeps the daemon it is
    # pointed at when `DOCKER_HOST` is not set.
    #
    # `docker context use colima` does not export anything. It writes
    # `currentContext` into ~/.docker/config.json, and every later `docker`
    # command resolves the endpoint out of the store. A client that reads only
    # `DOCKER_HOST` therefore disagrees with the CLI on the same machine, and
    # falls back to /var/run/docker.sock -- which Docker Desktop happens to
    # symlink, and Colima, Rancher Desktop, rootless Docker and Podman
    # generally do not. The failure is a connection refused with a correct
    # looking environment, which is a bad way to spend an afternoon.
    #
    # The store is a directory per context, named for the SHA-256 of the
    # context's own name, holding a meta.json:
    #
    #   ~/.docker/contexts/meta/<sha256(name)>/meta.json
    #   ~/.docker/contexts/tls/<sha256(name)>/docker/{ca,cert,key}.pem
    #
    # Every failure here is soft. An unreadable store, a malformed meta.json or
    # a context that no longer exists all mean "no context", because falling
    # back to the platform default is what the CLI does and is more useful than
    # refusing to start.
    module Context
      # The context name that means "no context": use DOCKER_HOST, or the
      # platform's default socket. It has no entry in the store.
      DEFAULT = "default"

      module_function

      # Resolve the endpoint the CLI would use, if any.
      #
      # @param env [Hash] the environment to read
      # @param root [String, nil] the Docker configuration directory
      # @return [Hash, nil] with :url and optionally :tls, or nil when no
      #   context applies
      def resolve(env = ENV, root: nil)
        root ||= config_root(env)
        name = current_name(env, root)
        return nil if name.nil? || name.empty? || name == DEFAULT

        endpoint(name, root)
      end

      # The active context's name: DOCKER_CONTEXT first, then whatever
      # `docker context use` last wrote into config.json.
      #
      # @param env [Hash]
      # @param root [String]
      # @return [String, nil]
      def current_name(env = ENV, root = config_root(env))
        from_env = env["DOCKER_CONTEXT"]
        return from_env unless from_env.nil? || from_env.empty?

        config = read_json(File.join(root, "config.json"))
        config.is_a?(Hash) ? config["currentContext"] : nil
      end

      # @param name [String] a context name
      # @param root [String] the Docker configuration directory
      # @return [Hash, nil] with :url and optionally :tls
      def endpoint(name, root = config_root)
        digest = Digest::SHA256.hexdigest(name)
        meta = read_json(File.join(root, "contexts", "meta", digest, "meta.json"))
        host = meta.dig("Endpoints", "docker", "Host") if meta.is_a?(Hash)
        return nil if host.nil? || host.empty?

        resolved = { url: host }
        tls = tls_material(root, digest, skip_verify: meta.dig("Endpoints", "docker", "SkipTLSVerify"))
        resolved[:tls] = tls unless tls.empty?
        resolved
      end

      # @param env [Hash]
      # @return [String] the Docker configuration directory
      def config_root(env = ENV)
        configured = env["DOCKER_CONFIG"]
        return configured unless configured.nil? || configured.empty?

        File.join(Dir.home, ".docker")
      rescue ArgumentError
        # Dir.home raises when there is no home to speak of, which happens in
        # stripped containers and some CI images.
        ".docker"
      end

      # A context may carry its own TLS material, which is how `docker context
      # create --docker host=tcp://...,ca=...,cert=...,key=...` stores it.
      #
      # @return [Hash]
      # @api private
      def tls_material(root, digest, skip_verify: false)
        directory = File.join(root, "contexts", "tls", digest, "docker")
        material = { ca_file: "ca.pem", cert_file: "cert.pem", key_file: "key.pem" }
          .filter_map { |key, file|
            path = File.join(directory, file)
            [key, path] if File.readable?(path)
          }.to_h

        return {} if material.empty?

        material.merge(verify: !skip_verify)
      end

      # @return [Object, nil]
      # @api private
      def read_json(path)
        return nil unless File.readable?(path)

        JSON.parse(File.read(path))
      rescue JSON::ParserError, SystemCallError
        nil
      end
    end
  end
end
