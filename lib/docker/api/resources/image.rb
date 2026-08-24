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
      # Pushes the reference this object stands for, not the whole repository.
      # The daemon pushes every tag under a repository when it is given no tag
      # at all, so leaving it out meant `image.push` on an image tagged both
      # `app:1.0` and `app:latest` pushed both -- an unwelcome surprise when
      # only one of them was meant to be published. `tag:` overrides; to push a
      # whole repository deliberately, ask the daemon for it directly with
      # `client.operations.image_push(name: repo, x_registry_auth: ...)`.
      #
      # @param tag [String, nil] which tag to push, defaulting to this image's own
      # @param auth [String, nil] an X-Registry-Auth value; resolved from the
      #   local Docker configuration when omitted
      # @param platform [String, Hash, nil] which variant to push
      # @yieldparam event [Hash] progress events as they arrive
      # @return [self]
      # @raise [Docker::API::Error] if the image carries no repository tag
      def push(tag: nil, auth: nil, platform: nil, &block)
        repo, own_tag = self.class.split_reference(pushable_reference)
        tag ||= own_tag
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
      # Three colons can appear in a reference and only one of them separates a
      # tag:
      #
      #   localhost:5000/app                  the colon is a registry port
      #   alpine@sha256:1a2b...               the colon is inside a digest
      #   registry.io/team/app:1.0            the colon is the tag separator
      #
      # The digest form has to be taken off first, because "@" binds looser
      # than the colon inside "sha256:..." and a right-hand partition on ":"
      # would otherwise split the digest itself -- turning "alpine@sha256:1a2b"
      # into the repository "alpine@sha256", which cannot exist. The daemon
      # wants the digest whole, as the tag: `?fromImage=alpine&tag=sha256:1a2b`
      # is exactly what `docker pull alpine@sha256:1a2b` sends.
      #
      # @param reference [String]
      # @return [Array(String, String)] the repository and the tag or digest
      #
      # @example
      #   split_reference("alpine")              #=> ["alpine", "latest"]
      #   split_reference("localhost:5000/app")  #=> ["localhost:5000/app", "latest"]
      #   split_reference("alpine@sha256:1a2b")  #=> ["alpine", "sha256:1a2b"]
      def self.split_reference(reference)
        value = reference.to_s
        repo, separator, digest = value.rpartition("@")
        return [repo, digest] unless separator.empty?

        repo, _, tag = value.rpartition(":")
        return [value, "latest"] if repo.empty? || tag.include?("/")

        [repo, tag]
      end

      # Put a repository and a tag or digest back together.
      #
      # The inverse of {.split_reference}, and it has to know which of the two
      # it was handed: a tag joins with ":" and a digest joins with "@". A tag
      # can never contain a colon, so the colon is the tell.
      #
      # @param repo [String]
      # @param tag [String, nil]
      # @return [String]
      #
      # @example
      #   join_reference("alpine", "3.20")         #=> "alpine:3.20"
      #   join_reference("alpine", "sha256:1a2b")  #=> "alpine@sha256:1a2b"
      def self.join_reference(repo, tag)
        return repo.to_s if tag.to_s.empty?

        tag.to_s.include?(":") ? "#{repo}@#{tag}" : "#{repo}:#{tag}"
      end

      # The repository reference this image can be pushed under.
      #
      # An image id is not one. Falling back to it produced a request against
      # the repository "sha256", because splitting "sha256:1a2b..." on the last
      # colon looks exactly like splitting a tag -- a confusing 404 in place of
      # the real problem, which is that nothing has named this image yet.
      # Untagged layers report `<none>:<none>`, which is not a name either.
      #
      # @return [String]
      # @raise [Docker::API::Error]
      # @api private
      def pushable_reference
        reference = tags.reject { |candidate| candidate.start_with?("<none>") }.first
        return reference if reference

        raise Error.new(
          "image #{id.to_s[0, 19]} has no repository tag, so there is nothing to push it as. " \
          "Give it one first with #tag.",
          operation: "image_push"
        )
      end
      private :pushable_reference

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
