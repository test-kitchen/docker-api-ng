# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Generator
  # Emits RBS signatures for the generated operations layer.
  #
  # Types are what turn an API upgrade from a hopeful regeneration into a
  # mechanical one: when a parameter disappears from the specification, it
  # disappears from the signature, and the type checker names every caller that
  # still passes it rather than leaving them to find out from the daemon.
  class RBSEmitter
    # @param operations [Array<Generator::Operation>]
    # @param api_version [String]
    def initialize(operations, api_version:)
      @operations = operations
      @api_version = api_version
    end

    # @return [String] RBS source
    def render
      lines = [header, "", "module Docker", "  module API", "    class Operations"]
      lines << "      attr_reader connection: Docker::API::Connection"
      lines << "      def initialize: (Docker::API::Connection connection) -> void"
      lines << ""
      @operations.each { |operation| lines << "      #{signature(operation)}" }
      lines << "    end"
      lines << "  end"
      lines << "end"
      "#{lines.join("\n")}\n"
    end

    private

    # @return [String]
    def header
      <<~BANNER.rstrip
        # GENERATED -- do not edit.
        #
        # Source:     data/swagger/v#{@api_version}.yaml (Docker Engine API v#{@api_version})
        # Generator:  tools/generator/rbs_emitter.rb
        # Regenerate: bundle exec rake api:generate
      BANNER
    end

    # @param operation [Generator::Operation]
    # @return [String]
    def signature(operation)
      parts = operation.required_params.map { |param| "#{param.ruby_name}: #{param.rbs_type}" } +
        operation.optional_params.map { |param| "?#{param.ruby_name}: #{param.rbs_type}?" }

      "def #{operation.method_name}: (#{parts.join(", ")}) " \
        "?{ (String) -> void } -> Docker::API::Response"
    end
  end
end
