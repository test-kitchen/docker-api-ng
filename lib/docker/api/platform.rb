# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Docker
  module API
    # Platform selectors, in the two encodings the Engine API uses for them.
    #
    # The API is not consistent here, and the inconsistency is silent. Some
    # endpoints want the familiar string:
    #
    #   POST /containers/create?platform=linux/arm64
    #   POST /build?platform=linux/arm64
    #   POST /images/create?platform=linux/arm64
    #
    # while others want a JSON-encoded OCI platform object:
    #
    #   GET  /images/{name}/json?platform={"os":"linux","architecture":"arm64"}
    #   POST /images/{name}/push?platform={"os":"linux","architecture":"arm64"}
    #   GET  /images/{name}/history?platform={...}
    #
    # Sending the string where the object is expected fails with
    # `400 failed to parse platform: invalid character 'l'`, which does not
    # obviously mean "wrong encoding" to anyone reading it for the first time.
    #
    # Callers of this gem write `"linux/arm64"` everywhere and the ergonomic
    # layer encodes whichever form the endpoint in question wants.
    module Platform
      module_function

      # Parse a platform into its OCI object form.
      #
      # @param value [String, Hash, nil] "os/arch", "os/arch/variant", an
      #   already-built OCI hash, or nil
      # @return [Hash, nil] with "os", "architecture" and optionally "variant"
      #
      # @example
      #   Platform.oci("linux/arm64")   #=> {"os"=>"linux", "architecture"=>"arm64"}
      #   Platform.oci("linux/arm/v7")  #=> {"os"=>"linux", "architecture"=>"arm", "variant"=>"v7"}
      def oci(value)
        return nil if value.nil?
        return value if value.is_a?(Hash)

        os, architecture, variant = value.to_s.split("/", 3)
        return nil if os.nil? || os.empty?

        { "os" => os, "architecture" => architecture, "variant" => variant }.compact
      end

      # Render a platform in the `os[/arch[/variant]]` string form.
      #
      # @param value [String, Hash, nil]
      # @return [String, nil]
      #
      # @example
      #   Platform.string("os" => "linux", "architecture" => "arm64") #=> "linux/arm64"
      def string(value)
        return nil if value.nil?
        return value if value.is_a?(String)

        [value["os"] || value[:os],
         value["architecture"] || value[:architecture],
         value["variant"] || value[:variant]].compact.join("/")
      end
    end
  end
end
