# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

require "yaml"
require_relative "operation"

module Generator
  # Reads Docker's Swagger 2.0 definition of the Engine API.
  #
  # This is the only part of the toolchain that knows the specification's
  # shape. Everything downstream works from {Generator::Operation} values, so
  # a future move to OpenAPI 3 changes this file and nothing else.
  class SpecReader
    # @return [String] the path to the specification
    attr_reader :path

    # @param path [String] path to a swagger.yaml
    def initialize(path)
      @path = path
    end

    # @return [String] the API version the document describes, e.g. "1.55"
    def api_version
      document.dig("info", "version")
    end

    # Every operation in the document, sorted for a stable diff.
    #
    # Ordering matters more than it looks: the generated files are committed,
    # so an unstable sort would produce a large meaningless diff on every
    # regeneration and hide the real change.
    #
    # @return [Array<Generator::Operation>]
    def operations
      @operations ||= document["paths"].flat_map do |path, verbs|
        verbs.filter_map do |verb, definition|
          next unless definition.is_a?(Hash) && definition["operationId"]

          build_operation(path, verb, definition)
        end
      end.sort_by { |operation| [operation.tag.to_s, operation.id] }
    end

    private

    # `aliases: true` is required: the document uses YAML anchors to share
    # parameter definitions between endpoints.
    #
    # @return [Hash]
    def document
      @document ||= YAML.safe_load_file(path, aliases: true)
    end

    # @return [Generator::Operation]
    def build_operation(path, verb, definition)
      Operation.new(
        id: definition["operationId"],
        verb: verb.downcase.to_sym,
        path: path,
        parameters: (definition["parameters"] || []).map { |p| build_parameter(p) },
        responses: build_responses(definition["responses"]),
        summary: definition["summary"],
        description: definition["description"],
        tag: Array(definition["tags"]).first
      )
    end

    # @return [Generator::Parameter]
    def build_parameter(definition)
      location = definition["in"].to_sym
      Parameter.new(
        name: definition["name"],
        location: location,
        # A body parameter carries a `schema` rather than a `type`.
        type: definition["type"] || (location == :body ? "schema" : "string"),
        required: definition["required"] == true,
        description: definition["description"],
        collection_format: definition["collectionFormat"]
      )
    end

    # @return [Hash{Integer => String}]
    def build_responses(responses)
      (responses || {}).each_with_object({}) do |(code, definition), out|
        out[Integer(code)] = definition.is_a?(Hash) ? definition["description"].to_s : ""
      rescue ArgumentError, TypeError
        # A non-numeric key such as "default" carries no status to map.
        next
      end
    end
  end
end
