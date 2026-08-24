# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Generator
  # Turning the specification's prose into comments that read well in Ruby.
  #
  # Docker writes its descriptions as GitHub-flavoured Markdown aimed at ReDoc,
  # which means tables, code fences and paragraphs many hundreds of characters
  # long. Reproducing that verbatim would make the generated file unreadable,
  # so it is trimmed to the part that helps someone at a call site.
  module Text
    module_function

    # @param text [String, nil] specification prose
    # @param limit [Integer] characters to keep
    # @return [String, nil] a single-line summary
    def summarize(text, limit: 240)
      return nil if text.nil? || text.strip.empty?

      first = text.strip.split(/\n\s*\n/).first.to_s
      flat = first.gsub(/\s+/, " ").strip
      flat = "#{flat[0, limit].rstrip}..." if flat.length > limit
      flat
    end

    # @param text [String] a single line
    # @param width [Integer] columns available for the text itself
    # @param prefix [String] what each line starts with
    # @return [Array<String>] wrapped comment lines
    def wrap(text, width: 74, prefix: "      # ")
      words = text.split(" ")
      lines = []
      current = +""

      words.each do |word|
        if current.empty?
          current = word.dup
        elsif current.length + 1 + word.length <= width
          current << " " << word
        else
          lines << current
          current = word.dup
        end
      end
      lines << current unless current.empty?
      lines.map { |line| "#{prefix}#{line}".rstrip }
    end
  end
end
