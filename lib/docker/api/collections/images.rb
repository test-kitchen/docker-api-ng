# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Docker
  module API
    # The images on a daemon.
    #
    # @example
    #   client.images.pull("alpine:3.20", platform: "linux/arm64")
    #   client.images.build(context: "./app", tag: "app:dev")
    class Images < Collection
      # List images.
      #
      # @param all [Boolean] include intermediate layers
      # @param filters [Hash, nil] daemon-side filters
      # @param digests [Boolean] include repository digests
      # @return [Array<Docker::API::Image>] partial resources
      def all(all: false, filters: nil, digests: false)
        operations.image_list(all: all, filters: filters, digests: digests)
          .json.map { |payload| Image.new(client: client, raw: payload, partial: true) }
      end

      # Fetch one image.
      #
      # @param name [String] a reference, id or digest
      # @param platform [String, Hash, nil] which platform's image to describe,
      #   as "linux/arm64" or an OCI platform hash
      # @return [Docker::API::Image]
      # @raise [Docker::API::NotFound] if there is no such image
      def get(name, platform: nil)
        Image.new(
          client: client,
          # This endpoint wants the OCI object form, unlike pull and build,
          # which want the string. See Docker::API::Platform.
          raw: operations.image_inspect(name: name, platform: Platform.oci(platform)).json,
          partial: false
        )
      end

      # Whether an image is present locally.
      #
      # @param name [String] a reference, id or digest
      # @param platform [String, nil] which platform to ask about
      # @return [Boolean]
      def exist?(name, platform: nil)
        !get(name, platform: platform).nil?
      rescue NotFound
        false
      end

      # Fetch an image, pulling it first if the daemon does not have it.
      #
      # @param reference [String] the image to ensure is present
      # @param platform [String, Hash, nil] the platform to select or pull
      # @param auth [String, nil] an X-Registry-Auth value
      # @yieldparam event [Hash] pull progress, when a pull is needed
      # @return [Docker::API::Image]
      def ensure(reference, platform: nil, auth: nil, &block)
        get(reference, platform: platform)
      rescue NotFound
        pull(reference, platform: platform, auth: auth, &block)
      end

      # Pull an image from a registry.
      #
      # Credentials are resolved for the registry in the reference, so pulling
      # from two private registries in one process needs no setup between
      # calls. Pass `auth:` to override.
      #
      # @param reference [String] "alpine:3.20", "registry.io/team/app:1.0"
      # @param platform [String, Hash, nil] the platform to pull, as
      #   "linux/arm64" or an OCI platform hash
      # @param auth [String, nil] an X-Registry-Auth value
      # @yieldparam event [Hash] progress events as they arrive
      # @return [Docker::API::Image]
      #
      # @example Watching progress
      #   client.images.pull("alpine:3.20") { |event| puts event["status"] }
      def pull(reference, platform: nil, auth: nil, &block)
        repo, tag = Image.split_reference(reference)
        credentials = auth || Auth.resolve(Image.registry_for(repo))

        stream = block ? Stream::JSONLines.new(&block) : nil
        # Pull wants the string form; inspect below wants the object form.
        operations.image_create(
          from_image: repo, tag: tag, platform: Platform.string(platform),
          x_registry_auth: credentials
        ) { |chunk| stream << chunk if stream }

        get(tag.to_s.empty? ? repo : "#{repo}:#{tag}", platform: platform)
      end

      # Build an image.
      #
      # The context may be a directory, which is tarred honouring its
      # .dockerignore, or a Dockerfile given as a string for the common case of
      # a short generated build with no accompanying files.
      #
      # @param context [String, IO, nil] a directory path, or tar bytes
      # @param dockerfile [String, nil] Dockerfile contents, when there is no
      #   directory, or the name of the Dockerfile within the context
      # @param tag [String, nil] the reference to give the result
      # @param platform [String, Hash, nil] the platform to build for
      # @param nocache [Boolean] ignore the layer cache
      # @param rm [Boolean] remove intermediate containers
      # @param pull [Boolean] always re-pull the base image
      # @param buildargs [Hash, nil] --build-arg values
      # @param labels [Hash, nil] labels for the resulting image
      # @param target [String, nil] which stage of a multi-stage build to stop at
      # @yieldparam event [Hash] build output as it arrives
      # @return [Docker::API::Image]
      # @raise [Docker::API::Error] if the daemon reports a build failure
      #
      # @example Building from a directory
      #   client.images.build(context: "./app", tag: "app:dev") do |event|
      #     print event["stream"]
      #   end
      #
      # @example Building from a Dockerfile in memory
      #   client.images.build(dockerfile: "FROM alpine\nRUN apk add curl\n", tag: "curl:dev")
      def build(context: nil, dockerfile: nil, tag: nil, platform: nil, nocache: false,
        rm: true, pull: false, buildargs: nil, labels: nil, target: nil, &block)
        archive, dockerfile_name = build_context(context, dockerfile)
        image_id = nil
        failure = nil

        stream = Stream::JSONLines.new do |event|
          image_id ||= event.dig("aux", "ID")
          failure ||= event["error"]
          block&.call(event)
        end

        operations.image_build(
          body: archive, content_type: "application/x-tar",
          t: tag, platform: Platform.string(platform), nocache: nocache, rm: rm, pull: pull,
          dockerfile: dockerfile_name, target: target,
          buildargs: buildargs, labels: labels
        ) { |chunk| stream << chunk }

        # The daemon reports build failures inside a 200 response rather than
        # as a status code, so a build that failed looks like a success to
        # anything that only checks HTTP.
        raise Error.new("image build failed: #{failure}", operation: "image_build") if failure

        get(tag || image_id)
      end

      # Remove unused images.
      #
      # @param filters [Hash, nil] which images to consider
      # @return [Hash] what was deleted and how much space it freed
      def prune(filters: nil)
        operations.image_prune(filters: filters).json
      end

      # Search Docker Hub.
      #
      # @param term [String] what to search for
      # @param limit [Integer, nil] how many results to return
      # @param filters [Hash, nil] search filters
      # @return [Array<Hash>]
      def search(term, limit: nil, filters: nil)
        operations.image_search(term: term, limit: limit, filters: filters).json
      end

      private

      # @return [Array(IO, String, nil)] the archive and the Dockerfile name
      def build_context(context, dockerfile)
        return [Tar.pack_dockerfile(dockerfile), "Dockerfile"] if context.nil? && dockerfile

        raise ArgumentError, "build needs a context: or a dockerfile:" if context.nil?
        return [context, dockerfile] unless context.is_a?(String) && File.directory?(context)

        [Tar.pack_directory(context), dockerfile]
      end
    end
  end
end
