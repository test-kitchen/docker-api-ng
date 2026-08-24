# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Docker
  module API
    # An image on the daemon.
    class Image < Resource
      # @return [Array<String>] every repository:tag this image answers to
      def tags
        detail("RepoTags") || []
      end

      # @return [Array<String>] the image's repository digests
      def digests
        detail("RepoDigests") || []
      end

      # @return [String, nil] the first tag, which is what people usually mean
      #   when they say "the image name"
      def name
        tags.first
      end

      # @return [Integer, nil] size on disk, in bytes
      def size
        detail("Size")
      end

      # @return [Hash] the image's labels
      def labels
        detail("Config.Labels", "Labels") || {}
      end

      # @return [String, nil] the platform this image was built for
      def platform
        os = detail("Os")
        architecture = detail("Architecture")
        return nil if os.nil? || architecture.nil?

        variant = detail("Variant")
        [os, architecture, variant].compact.join("/")
      end

      # @return [self]
      def reload
        replace_raw(operations.image_inspect(name: id).json)
      end

      # Give this image another name.
      #
      # @param reference [String] a full "repo:tag", or just a repo
      # @return [self]
      #
      # @example
      #   image.tag("registry.example.com/team/app:2026.08")
      def tag(reference)
        repo, tag = self.class.split_reference(reference)
        operations.image_tag(name: id, repo: repo, tag: tag)
        reload
      end

      # @param force [Boolean] remove even if tagged or in use
      # @param noprune [Boolean] keep untagged parents
      # @return [Array<Hash>] what the daemon deleted or untagged
      def remove(force: false, noprune: false)
        operations.image_delete(name: id, force: force, noprune: noprune).json
      end

      # Push this image to its registry.
      #
      # @param tag [String, nil] which tag to push
      # @param auth [String, nil] an X-Registry-Auth value; resolved from the
      #   local Docker configuration when omitted
      # @param platform [String, Hash, nil] which variant to push
      # @yieldparam event [Hash] progress events as they arrive
      # @return [self]
      def push(tag: nil, auth: nil, platform: nil, &block)
        reference = name || id
        repo = self.class.split_reference(reference).first
        credentials = auth || Auth.resolve(self.class.registry_for(repo)) || Auth.encode({})

        stream = block ? Stream::JSONLines.new(&block) : nil
        operations.image_push(
          name: repo, tag: tag, x_registry_auth: credentials,
          platform: Platform.oci(platform)
        ) do |chunk|
          stream << chunk if stream
        end
        self
      end

      # @param platform [String, Hash, nil] which variant's history to read
      # @return [Array<Hash>] the image's layer history
      def history(platform: nil)
        operations.image_history(name: id, platform: Platform.oci(platform)).json
      end

      # Write the image out as a tar archive.
      #
      # @yieldparam chunk [String] tar bytes, when a block is given
      # @return [String, self]
      def save(&block)
        return operations.image_get(name: id).body unless block

        operations.image_get(name: id, &block)
        self
      end

      # Split "registry.io/team/app:1.0" into its repository and tag.
      #
      # The colon in a registry's port is the trap here: "localhost:5000/app"
      # has a colon that is not a tag separator, so only a colon after the last
      # slash counts.
      #
      # @param reference [String]
      # @return [Array(String, String)] the repository and the tag
      def self.split_reference(reference)
        repo, _, tag = reference.to_s.rpartition(":")
        return [reference.to_s, "latest"] if repo.empty? || tag.include?("/")

        [repo, tag]
      end

      # @param repo [String] a repository, possibly registry-qualified
      # @return [String, nil] the registry hostname, or nil for Docker Hub
      def self.registry_for(repo)
        first = repo.to_s.split("/").first
        return nil if first.nil?
        # A first segment is a registry only if it looks like a host: it has a
        # dot, a port, or is literally localhost. Otherwise it is a Hub org.
        return first if first.include?(".") || first.include?(":") || first == "localhost"

        nil
      end
    end
  end
end
