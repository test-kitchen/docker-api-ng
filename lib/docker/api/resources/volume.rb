# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Docker
  module API
    # A volume on the daemon.
    #
    # Volumes are identified by name rather than by a generated id, so {#id}
    # and {#name} are the same value.
    class Volume < Resource
      # @return [String, nil] the volume's name
      def name
        raw["Name"]
      end

      # @return [String, nil] the volume's name, which is also its identifier
      def id
        name
      end

      # @return [String, nil] the driver backing this volume
      def driver
        detail("Driver")
      end

      # @return [String, nil] where the daemon keeps the volume's contents
      def mountpoint
        detail("Mountpoint")
      end

      # @return [Hash] the volume's labels
      def labels
        detail("Labels") || {}
      end

      # @return [self]
      def reload
        replace_raw(operations.volume_inspect(name: name).json)
      end

      # @param force [Boolean] remove even if the driver objects
      # @return [void]
      def remove(force: false)
        operations.volume_delete(name: name, force: force)
        nil
      end
    end
  end
end
