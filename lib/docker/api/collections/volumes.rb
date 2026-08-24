# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Docker
  module API
    # The volumes on a daemon.
    class Volumes < Collection
      # @param filters [Hash, nil] daemon-side filters
      # @return [Array<Docker::API::Volume>]
      def all(filters: nil)
        payload = operations.volume_list(filters: filters).json
        Array(payload["Volumes"]).map do |entry|
          Volume.new(client: client, raw: entry, partial: false)
        end
      end

      # @return [Array<String>] names of volumes the daemon could not inspect
      def warnings(filters: nil)
        Array(operations.volume_list(filters: filters).json["Warnings"])
      end

      # @param name [String] the volume's name
      # @return [Docker::API::Volume]
      # @raise [Docker::API::NotFound] if there is no such volume
      def get(name)
        Volume.new(client: client, raw: operations.volume_inspect(name: name).json, partial: false)
      end

      # Create a volume.
      #
      # @param name [String, nil] a name, or nil to let the daemon choose one
      # @param driver [String, nil] the driver to back it with
      # @param labels [Hash, nil] labels for the volume
      # @param driver_opts [Hash, nil] driver-specific options
      # @return [Docker::API::Volume]
      def create(name = nil, driver: nil, labels: nil, driver_opts: nil)
        body = {
          "Name" => name, "Driver" => driver,
          "Labels" => labels, "DriverOpts" => driver_opts
        }.compact

        Volume.new(client: client, raw: operations.volume_create(body: body).json, partial: false)
      end

      # @param filters [Hash, nil] which volumes to consider
      # @return [Hash] what was deleted and how much space it freed
      def prune(filters: nil)
        operations.volume_prune(filters: filters).json
      end
    end
  end
end
