# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Docker
  module API
    # Builds request bodies without making callers shout in PascalCase.
    module Body
      module_function

      # Convert top-level snake_case keys to the PascalCase the daemon uses.
      #
      # Only the top level is converted, deliberately. Nested structures are
      # passed through exactly as given, because their keys are frequently data
      # rather than field names -- `Labels`, `ExposedPorts`, `PortBindings` and
      # `Sysctls` are all maps whose keys belong to the user. A recursive
      # converter would mangle `{ "com.example/team" => "infra" }` into
      # something the daemon has never heard of.
      #
      # Keys that already look like the daemon's own are left alone, so a body
      # copied verbatim out of Docker's documentation keeps working.
      #
      # @param attributes [Hash] a body in either convention
      # @return [Hash] a body in the daemon's convention
      #
      # @example
      #   Body.build(image: "alpine", host_config: { "Binds" => ["/a:/b"] })
      #   #=> { "Image" => "alpine", "HostConfig" => { "Binds" => ["/a:/b"] } }
      def build(attributes)
        (attributes || {}).each_with_object({}) do |(key, value), out|
          out[camelize(key)] = value unless value.nil?
        end
      end

      # @param key [String, Symbol]
      # @return [String] the daemon's spelling of a field name
      def camelize(key)
        name = key.to_s
        # Already PascalCase, or a literal the caller means verbatim.
        return name if name.match?(/\A[A-Z]/)

        name.split("_").map { |part| part.sub(/\A(.)/) { Regexp.last_match(1).upcase } }.join
      end
    end
  end
end
