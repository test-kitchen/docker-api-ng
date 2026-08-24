# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

require "rubygems/package" unless defined?(Gem::Package)

module Docker
  module API
    # Packs a build context into the tar archive the daemon expects.
    #
    # RubyGems ships `Gem::Package::TarWriter` with every Ruby, so building a
    # context needs no dependency and no shelling out to `tar` -- which also
    # means the behaviour is identical on Windows, where there may be no `tar`
    # to shell out to.
    module Tar
      module_function

      # Pack a directory into an uncompressed tar archive.
      #
      # @param directory [String] the build context root
      # @param ignore [Array<String>, nil] patterns to exclude. Read from the
      #   context's .dockerignore when not given.
      # @return [StringIO] the archive, rewound and ready to send
      #
      # @example
      #   Tar.pack_directory("./app")
      def pack_directory(directory, ignore: nil)
        root = File.expand_path(directory)
        raise ArgumentError, "build context #{directory} is not a directory" unless File.directory?(root)

        patterns = ignore || read_dockerignore(root)
        buffer = StringIO.new(+"".b)

        Gem::Package::TarWriter.new(buffer) do |tar|
          each_entry(root, patterns) do |absolute, relative|
            add_entry(tar, absolute, relative)
          end
        end

        buffer.rewind
        buffer
      end

      # Pack a single in-memory Dockerfile into a context of its own.
      #
      # Useful for the common case of a short generated Dockerfile with no
      # accompanying files, where writing a temporary directory first would be
      # ceremony for its own sake.
      #
      # @param contents [String] the Dockerfile
      # @param files [Hash{String => String}] additional files, path to content
      # @return [StringIO] the archive, rewound and ready to send
      def pack_dockerfile(contents, files: {})
        buffer = StringIO.new(+"".b)

        Gem::Package::TarWriter.new(buffer) do |tar|
          write_file(tar, "Dockerfile", contents, 0o644)
          files.each { |path, body| write_file(tar, path, body, 0o644) }
        end

        buffer.rewind
        buffer
      end

      # @param root [String]
      # @return [Array<String>] patterns from .dockerignore, or an empty list
      def read_dockerignore(root)
        path = File.join(root, ".dockerignore")
        return [] unless File.readable?(path)

        File.readlines(path, chomp: true)
          .map(&:strip)
          .reject { |line| line.empty? || line.start_with?("#") }
      end

      # Docker's ignore rules allow a later "!" pattern to re-include something
      # an earlier pattern excluded, so the last matching rule wins rather than
      # the first.
      #
      # @param relative [String] a context-relative path
      # @param patterns [Array<String>]
      # @return [Boolean] whether the path should be left out
      def ignored?(relative, patterns)
        decision = false

        patterns.each do |pattern|
          negated = pattern.start_with?("!")
          candidate = negated ? pattern[1..] : pattern
          decision = !negated if matches?(relative, candidate)
        end

        decision
      end

      # @param relative [String]
      # @param pattern [String]
      # @return [Boolean]
      def matches?(relative, pattern)
        pattern = pattern.chomp("/")
        return true if File.fnmatch?(pattern, relative, File::FNM_PATHNAME)

        # A directory pattern excludes everything beneath it.
        File.fnmatch?("#{pattern}/**", relative, File::FNM_PATHNAME) ||
          relative.start_with?("#{pattern}/")
      end

      # @return [void]
      # @api private
      def each_entry(root, patterns)
        Dir.glob("**/*", File::FNM_DOTMATCH, base: root).sort.each do |relative|
          next if [".", ".."].include?(File.basename(relative))
          next if ignored?(relative, patterns)

          yield File.join(root, relative), relative
        end
      end

      # @return [void]
      # @api private
      def add_entry(tar, absolute, relative)
        stat = File.lstat(absolute)

        if stat.directory?
          tar.mkdir(relative, stat.mode)
        elsif stat.symlink?
          tar.add_symlink(relative, File.readlink(absolute), stat.mode)
        elsif stat.file?
          tar.add_file_simple(relative, stat.mode, stat.size) do |entry|
            File.open(absolute, "rb") { |file| IO.copy_stream(file, entry) }
          end
        end
      end

      # @return [void]
      # @api private
      def write_file(tar, path, contents, mode)
        bytes = contents.to_s.b
        tar.add_file_simple(path, mode, bytes.bytesize) { |entry| entry.write(bytes) }
      end
    end
  end
end
