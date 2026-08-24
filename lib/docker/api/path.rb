# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Docker
  module API
    # Escaping for values interpolated into a request path.
    module Path
      # Characters that may appear unescaped in a path. This is RFC 3986's
      # `pchar` set plus the separator itself.
      #
      # Keeping "/" and ":" unescaped is the point. Image references are
      # `registry.example.com/team/image:tag`, and the daemon's router matches
      # those slashes as path structure -- percent-encoding them turns a valid
      # reference into a 404. Everything genuinely unsafe (spaces, "?", "#",
      # "%") is still escaped.
      SAFE = %r{[^A-Za-z0-9\-._~!$&'()*+,;=:@/]}

      module_function

      # @param value [Object] a value being interpolated into a path
      # @return [String] the value, safe to place in a path
      #
      # @example
      #   Path.escape("registry.io/team/img:1.0") #=> "registry.io/team/img:1.0"
      #   Path.escape("weird name")               #=> "weird%20name"
      def escape(value)
        URI::DEFAULT_PARSER.escape(value.to_s, SAFE)
      end
    end
  end
end
