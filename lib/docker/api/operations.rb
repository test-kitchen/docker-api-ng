# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0
#
# GENERATED -- do not edit.
#
# Source:    data/swagger/v1.55.yaml (Docker Engine API v1.55)
# Generator: tools/generator/operations_emitter.rb
# Regenerate: bundle exec rake api:generate
# Upgrade:    bundle exec rake api:sync[1.56]
#
# Editing this file by hand means the next regeneration silently reverts
# your change. Fix the emitter or the vendored specification instead.

module Docker
  module API
    # Every operation the Docker Engine API defines, one method each.
    #
    # This layer is generated from Docker's own specification, so it is
    # complete by construction: if the daemon documents an endpoint, there is
    # a method for it, with every parameter that endpoint accepts. It is also
    # public API rather than an escape hatch -- reach for it directly whenever
    # the ergonomic layer has not grown sugar for what you need.
    #
    # Methods take keyword arguments named after the specification's
    # parameters, return a {Docker::API::Response}, and raise a
    # {Docker::API::Error} subclass for any status the endpoint does not
    # document as success.
    #
    # @example Calling an endpoint with no ergonomic wrapper
    #   client.operations.container_prune(filters: { "until" => ["24h"] })
    #
    # @example Streaming, by passing a block
    #   client.operations.system_events { |chunk| puts chunk }
    class Operations
      # @param connection [Docker::API::Connection] the connection to issue requests on
      def initialize(connection)
        @connection = connection
      end

      # @return [Docker::API::Connection] the connection in use
      attr_reader :connection

      # Create a config
      #
      # @!method config_create
      # Engine API: POST /configs/create
      #
      # @param body [Hash, nil] (body parameter 'body' in the API specification)
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::Conflict] 409 -- name conflicts with an existing
      # object
      # @raise [Docker::API::ServerError] 500 -- server error
      # @raise [Docker::API::ServerError] 503 -- node is not part of a swarm
      def config_create(body: nil, &block)
        connection.request(
          :post,
          "/configs/create",
          body: body,
          expects: [201],
          operation: "config_create",
          &block
        )
      end

      # Delete a config
      #
      # @!method config_delete
      # Engine API: DELETE /configs/{id}
      #
      # @param id [String] ID of the config
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- config not found
      # @raise [Docker::API::ServerError] 500 -- server error
      # @raise [Docker::API::ServerError] 503 -- node is not part of a swarm
      def config_delete(id:, &block)
        connection.request(
          :delete,
          "/configs/#{Path.escape(id)}",
          expects: [204],
          operation: "config_delete",
          &block
        )
      end

      # Inspect a config
      #
      # @!method config_inspect
      # Engine API: GET /configs/{id}
      #
      # @param id [String] ID of the config
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- config not found
      # @raise [Docker::API::ServerError] 500 -- server error
      # @raise [Docker::API::ServerError] 503 -- node is not part of a swarm
      def config_inspect(id:, &block)
        connection.request(
          :get,
          "/configs/#{Path.escape(id)}",
          expects: [200],
          operation: "config_inspect",
          &block
        )
      end

      # List configs
      #
      # @!method config_list
      # Engine API: GET /configs
      #
      # @param filters [String, nil] A JSON encoded value of the filters (a
      # `map[string][]string`) to process on the configs list.
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::ServerError] 500 -- server error
      # @raise [Docker::API::ServerError] 503 -- node is not part of a swarm
      def config_list(filters: nil, &block)
        connection.request(
          :get,
          "/configs",
          query: { "filters" => filters },
          expects: [200],
          operation: "config_list",
          &block
        )
      end

      # Update a Config
      #
      # @!method config_update
      # Engine API: POST /configs/{id}/update
      #
      # @param id [String] The ID or name of the config
      # @param version [Integer] The version number of the config object being
      # updated. This is required to avoid conflicting writes.
      # @param body [Hash, nil] The spec of the config to update. Currently,
      # only the Labels field can be updated. All other fields must remain
      # unchanged from the [ConfigInspect endpoint](#ope... (body parameter
      # 'body' in the API specification)
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::BadRequest] 400 -- bad parameter
      # @raise [Docker::API::NotFound] 404 -- no such config
      # @raise [Docker::API::ServerError] 500 -- server error
      # @raise [Docker::API::ServerError] 503 -- node is not part of a swarm
      def config_update(id:, version:, body: nil, &block)
        connection.request(
          :post,
          "/configs/#{Path.escape(id)}/update",
          query: { "version" => version },
          body: body,
          expects: [200],
          operation: "config_update",
          &block
        )
      end

      # Get an archive of a filesystem resource in a container
      #
      # Get a tar archive of a resource in the filesystem of container id.
      #
      # @!method container_archive
      # Engine API: GET /containers/{id}/archive
      #
      # @param id [String] ID or name of the container
      # @param path [String] Resource in the container’s filesystem to archive.
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::BadRequest] 400 -- Bad parameter
      # @raise [Docker::API::NotFound] 404 -- Container or path does not exist
      # @raise [Docker::API::ServerError] 500 -- server error
      def container_archive(id:, path:, &block)
        connection.request(
          :get,
          "/containers/#{Path.escape(id)}/archive",
          query: { "path" => path },
          expects: [200],
          operation: "container_archive",
          &block
        )
      end

      # Get information about files in a container
      #
      # A response header `X-Docker-Container-Path-Stat` is returned, containing a
      # base64 - encoded JSON object with some filesystem header information about
      # the path.
      #
      # @!method container_archive_info
      # Engine API: HEAD /containers/{id}/archive
      #
      # @param id [String] ID or name of the container
      # @param path [String] Resource in the container’s filesystem to archive.
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::BadRequest] 400 -- Bad parameter
      # @raise [Docker::API::NotFound] 404 -- Container or path does not exist
      # @raise [Docker::API::ServerError] 500 -- Server error
      def container_archive_info(id:, path:, &block)
        connection.request(
          :head,
          "/containers/#{Path.escape(id)}/archive",
          query: { "path" => path },
          expects: [200],
          operation: "container_archive_info",
          &block
        )
      end

      # Attach to a container
      #
      # Attach to a container to read its output or send it input. You can attach
      # to the same container multiple times and you can reattach to containers
      # that have been detached.
      #
      # @!method container_attach
      # Engine API: POST /containers/{id}/attach
      #
      # @param id [String] ID or name of the container
      # @param detach_keys [String, nil] Override the key sequence for detaching
      # a container.Format is a single character `[a-Z]` or `ctrl-<value>` where
      # `<value>` is one of: `a-z`, `@`, `^`, `[`, `,`... (sent to the daemon as
      # 'detachKeys')
      # @param logs [Boolean, nil] Replay previous logs from the container.
      # @param stream [Boolean, nil] Stream attached streams from the time the
      # request was made onwards.
      # @param stdin [Boolean, nil] Attach to `stdin`
      # @param stdout [Boolean, nil] Attach to `stdout`
      # @param stderr [Boolean, nil] Attach to `stderr`
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::ClientError] 101 -- no error, hints proxy about
      # hijacking
      # @raise [Docker::API::BadRequest] 400 -- bad parameter
      # @raise [Docker::API::NotFound] 404 -- no such container
      # @raise [Docker::API::ServerError] 500 -- server error
      def container_attach(id:, detach_keys: nil, logs: nil, stream: nil, stdin: nil, stdout: nil, stderr: nil, &block)
        connection.request(
          :post,
          "/containers/#{Path.escape(id)}/attach",
          query: {
            "detachKeys" => detach_keys,
            "logs" => logs,
            "stream" => stream,
            "stdin" => stdin,
            "stdout" => stdout,
            "stderr" => stderr,
          },
          expects: [200],
          operation: "container_attach",
          &block
        )
      end

      # Attach to a container via a websocket
      #
      # @!method container_attach_websocket
      # Engine API: GET /containers/{id}/attach/ws
      #
      # @param id [String] ID or name of the container
      # @param detach_keys [String, nil] Override the key sequence for detaching
      # a container.Format is a single character `[a-Z]` or `ctrl-<value>` where
      # `<value>` is one of: `a-z`, `@`, `^`, `[`, `,`,... (sent to the daemon
      # as 'detachKeys')
      # @param logs [Boolean, nil] Return logs
      # @param stream [Boolean, nil] Return stream
      # @param stdin [Boolean, nil] Attach to `stdin`
      # @param stdout [Boolean, nil] Attach to `stdout`
      # @param stderr [Boolean, nil] Attach to `stderr`
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::ClientError] 101 -- no error, hints proxy about
      # hijacking
      # @raise [Docker::API::BadRequest] 400 -- bad parameter
      # @raise [Docker::API::NotFound] 404 -- no such container
      # @raise [Docker::API::ServerError] 500 -- server error
      def container_attach_websocket(id:, detach_keys: nil, logs: nil, stream: nil, stdin: nil, stdout: nil, stderr: nil, &block)
        connection.request(
          :get,
          "/containers/#{Path.escape(id)}/attach/ws",
          query: {
            "detachKeys" => detach_keys,
            "logs" => logs,
            "stream" => stream,
            "stdin" => stdin,
            "stdout" => stdout,
            "stderr" => stderr,
          },
          expects: [200],
          operation: "container_attach_websocket",
          &block
        )
      end

      # Get changes on a container’s filesystem
      #
      # Returns which files in a container's filesystem have been added, deleted,
      # or modified. The `Kind` of modification can be one of:
      #
      # @!method container_changes
      # Engine API: GET /containers/{id}/changes
      #
      # @param id [String] ID or name of the container
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- no such container
      # @raise [Docker::API::ServerError] 500 -- server error
      def container_changes(id:, &block)
        connection.request(
          :get,
          "/containers/#{Path.escape(id)}/changes",
          expects: [200],
          operation: "container_changes",
          &block
        )
      end

      # Create a container
      #
      # @!method container_create
      # Engine API: POST /containers/create
      #
      # @param body [Hash] Container to create (body parameter 'body' in the API
      # specification)
      # @param name [String, nil] Assign the specified name to the container.
      # Must match `/?[a-zA-Z0-9][a-zA-Z0-9_.-]+`.
      # @param platform [String, nil] Platform in the format
      # `os[/arch[/variant]]` used for image lookup.
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::BadRequest] 400 -- bad parameter
      # @raise [Docker::API::NotFound] 404 -- no such image
      # @raise [Docker::API::Conflict] 409 -- conflict
      # @raise [Docker::API::ServerError] 500 -- server error
      def container_create(body:, name: nil, platform: nil, &block)
        connection.request(
          :post,
          "/containers/create",
          query: { "name" => name, "platform" => platform },
          body: body,
          expects: [201],
          operation: "container_create",
          &block
        )
      end

      # Remove a container
      #
      # @!method container_delete
      # Engine API: DELETE /containers/{id}
      #
      # @param id [String] ID or name of the container
      # @param v [Boolean, nil] Remove anonymous volumes associated with the
      # container.
      # @param force [Boolean, nil] If the container is running, kill it before
      # removing it.
      # @param link [Boolean, nil] Remove the specified link associated with the
      # container.
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::BadRequest] 400 -- bad parameter
      # @raise [Docker::API::NotFound] 404 -- no such container
      # @raise [Docker::API::Conflict] 409 -- conflict
      # @raise [Docker::API::ServerError] 500 -- server error
      def container_delete(id:, v: nil, force: nil, link: nil, &block)
        connection.request(
          :delete,
          "/containers/#{Path.escape(id)}",
          query: { "v" => v, "force" => force, "link" => link },
          expects: [204],
          operation: "container_delete",
          &block
        )
      end

      # Export a container
      #
      # Export the contents of a container as a tarball.
      #
      # @!method container_export
      # Engine API: GET /containers/{id}/export
      #
      # @param id [String] ID or name of the container
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- no such container
      # @raise [Docker::API::ServerError] 500 -- server error
      def container_export(id:, &block)
        connection.request(
          :get,
          "/containers/#{Path.escape(id)}/export",
          expects: [200],
          operation: "container_export",
          &block
        )
      end

      # Inspect a container
      #
      # Return low-level information about a container.
      #
      # @!method container_inspect
      # Engine API: GET /containers/{id}/json
      #
      # @param id [String] ID or name of the container
      # @param size [Boolean, nil] Return the size of container as fields
      # `SizeRw` and `SizeRootFs`
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- no such container
      # @raise [Docker::API::ServerError] 500 -- server error
      def container_inspect(id:, size: nil, &block)
        connection.request(
          :get,
          "/containers/#{Path.escape(id)}/json",
          query: { "size" => size },
          expects: [200],
          operation: "container_inspect",
          &block
        )
      end

      # Kill a container
      #
      # Send a POSIX signal to a container, defaulting to killing to the
      # container.
      #
      # @!method container_kill
      # Engine API: POST /containers/{id}/kill
      #
      # @param id [String] ID or name of the container
      # @param signal [String, nil] Signal to send to the container as an
      # integer or string (e.g. `SIGINT`).
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- no such container
      # @raise [Docker::API::Conflict] 409 -- container is not running
      # @raise [Docker::API::ServerError] 500 -- server error
      def container_kill(id:, signal: nil, &block)
        connection.request(
          :post,
          "/containers/#{Path.escape(id)}/kill",
          query: { "signal" => signal },
          expects: [204],
          operation: "container_kill",
          &block
        )
      end

      # List containers
      #
      # Returns a list of containers. For details on the format, see the [inspect
      # endpoint](#operation/ContainerInspect).
      #
      # @!method container_list
      # Engine API: GET /containers/json
      #
      # @param all [Boolean, nil] Return all containers. By default, only
      # running containers are shown.
      # @param limit [Integer, nil] Return this number of most recently created
      # containers, including non-running ones.
      # @param size [Boolean, nil] Return the size of container as fields
      # `SizeRw` and `SizeRootFs`.
      # @param filters [String, nil] Filters to process on the container list,
      # encoded as JSON (a `map[string][]string`). For example, `{"status":
      # ["paused"]}` will only return paused containers.
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::BadRequest] 400 -- bad parameter
      # @raise [Docker::API::ServerError] 500 -- server error
      def container_list(all: nil, limit: nil, size: nil, filters: nil, &block)
        connection.request(
          :get,
          "/containers/json",
          query: { "all" => all, "limit" => limit, "size" => size, "filters" => filters },
          expects: [200],
          operation: "container_list",
          &block
        )
      end

      # Get container logs
      #
      # Get `stdout` and `stderr` logs from a container.
      #
      # @!method container_logs
      # Engine API: GET /containers/{id}/logs
      #
      # @param id [String] ID or name of the container
      # @param follow [Boolean, nil] Keep connection after returning logs.
      # @param stdout [Boolean, nil] Return logs from `stdout`
      # @param stderr [Boolean, nil] Return logs from `stderr`
      # @param since [Integer, nil] Only return logs since this time, as a UNIX
      # timestamp
      # @param until_ [Integer, nil] Only return logs before this time, as a
      # UNIX timestamp (sent to the daemon as 'until')
      # @param timestamps [Boolean, nil] Add timestamps to every log line
      # @param tail [String, nil] Only return this number of log lines from the
      # end of the logs. Specify as an integer or `all` to output all log lines.
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- no such container
      # @raise [Docker::API::ServerError] 500 -- server error
      def container_logs(
        id:,
        follow: nil,
        stdout: nil,
        stderr: nil,
        since: nil,
        until_: nil,
        timestamps: nil,
        tail: nil,
        &block
      )
        connection.request(
          :get,
          "/containers/#{Path.escape(id)}/logs",
          query: {
            "follow" => follow,
            "stdout" => stdout,
            "stderr" => stderr,
            "since" => since,
            "until" => until_,
            "timestamps" => timestamps,
            "tail" => tail,
          },
          expects: [200],
          operation: "container_logs",
          &block
        )
      end

      # Pause a container
      #
      # Use the freezer cgroup to suspend all processes in a container.
      #
      # @!method container_pause
      # Engine API: POST /containers/{id}/pause
      #
      # @param id [String] ID or name of the container
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- no such container
      # @raise [Docker::API::ServerError] 500 -- server error
      def container_pause(id:, &block)
        connection.request(
          :post,
          "/containers/#{Path.escape(id)}/pause",
          expects: [204],
          operation: "container_pause",
          &block
        )
      end

      # Delete stopped containers
      #
      # @!method container_prune
      # Engine API: POST /containers/prune
      #
      # @param filters [String, nil] Filters to process on the prune list,
      # encoded as JSON (a `map[string][]string`).
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::ServerError] 500 -- Server error
      def container_prune(filters: nil, &block)
        connection.request(
          :post,
          "/containers/prune",
          query: { "filters" => filters },
          expects: [200],
          operation: "container_prune",
          &block
        )
      end

      # Rename a container
      #
      # @!method container_rename
      # Engine API: POST /containers/{id}/rename
      #
      # @param id [String] ID or name of the container
      # @param name [String] New name for the container
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- no such container
      # @raise [Docker::API::Conflict] 409 -- name already in use
      # @raise [Docker::API::ServerError] 500 -- server error
      def container_rename(id:, name:, &block)
        connection.request(
          :post,
          "/containers/#{Path.escape(id)}/rename",
          query: { "name" => name },
          expects: [204],
          operation: "container_rename",
          &block
        )
      end

      # Resize a container TTY
      #
      # Resize the TTY for a container.
      #
      # @!method container_resize
      # Engine API: POST /containers/{id}/resize
      #
      # @param id [String] ID or name of the container
      # @param h [Integer] Height of the TTY session in characters
      # @param w [Integer] Width of the TTY session in characters
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- no such container
      # @raise [Docker::API::ServerError] 500 -- cannot resize container
      def container_resize(id:, h:, w:, &block)
        connection.request(
          :post,
          "/containers/#{Path.escape(id)}/resize",
          query: { "h" => h, "w" => w },
          expects: [200],
          operation: "container_resize",
          &block
        )
      end

      # Restart a container
      #
      # @!method container_restart
      # Engine API: POST /containers/{id}/restart
      #
      # @param id [String] ID or name of the container
      # @param signal [String, nil] Signal to send to the container as an
      # integer or string (e.g. `SIGINT`).
      # @param t [Integer, nil] Number of seconds to wait before killing the
      # container
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- no such container
      # @raise [Docker::API::ServerError] 500 -- server error
      def container_restart(id:, signal: nil, t: nil, &block)
        connection.request(
          :post,
          "/containers/#{Path.escape(id)}/restart",
          query: { "signal" => signal, "t" => t },
          expects: [204],
          operation: "container_restart",
          &block
        )
      end

      # Start a container
      #
      # @!method container_start
      # Engine API: POST /containers/{id}/start
      #
      # @param id [String] ID or name of the container
      # @param detach_keys [String, nil] Override the key sequence for detaching
      # a container. Format is a single character `[a-Z]` or `ctrl-<value>`
      # where `<value>` is one of: `a-z`, `@`, `^`, `[`, `,`... (sent to the
      # daemon as 'detachKeys')
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotModified] 304 -- container already started
      # @raise [Docker::API::NotFound] 404 -- no such container
      # @raise [Docker::API::ServerError] 500 -- server error
      def container_start(id:, detach_keys: nil, &block)
        connection.request(
          :post,
          "/containers/#{Path.escape(id)}/start",
          query: { "detachKeys" => detach_keys },
          expects: [204],
          operation: "container_start",
          &block
        )
      end

      # Get container stats based on resource usage
      #
      # This endpoint returns a live stream of a container’s resource usage
      # statistics.
      #
      # @!method container_stats
      # Engine API: GET /containers/{id}/stats
      #
      # @param id [String] ID or name of the container
      # @param stream [Boolean, nil] Stream the output. If false, the stats will
      # be output once and then it will disconnect.
      # @param one_shot [Boolean, nil] Only get a single stat instead of waiting
      # for 2 cycles. Must be used with `stream=false`. (sent to the daemon as
      # 'one-shot')
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- no such container
      # @raise [Docker::API::ServerError] 500 -- server error
      def container_stats(id:, stream: nil, one_shot: nil, &block)
        connection.request(
          :get,
          "/containers/#{Path.escape(id)}/stats",
          query: { "stream" => stream, "one-shot" => one_shot },
          expects: [200],
          operation: "container_stats",
          &block
        )
      end

      # Stop a container
      #
      # @!method container_stop
      # Engine API: POST /containers/{id}/stop
      #
      # @param id [String] ID or name of the container
      # @param signal [String, nil] Signal to send to the container as an
      # integer or string (e.g. `SIGINT`).
      # @param t [Integer, nil] Number of seconds to wait before killing the
      # container
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotModified] 304 -- container already stopped
      # @raise [Docker::API::NotFound] 404 -- no such container
      # @raise [Docker::API::ServerError] 500 -- server error
      def container_stop(id:, signal: nil, t: nil, &block)
        connection.request(
          :post,
          "/containers/#{Path.escape(id)}/stop",
          query: { "signal" => signal, "t" => t },
          expects: [204],
          operation: "container_stop",
          &block
        )
      end

      # List processes running inside a container
      #
      # On Unix systems, this is done by running the `ps` command. This endpoint
      # is not supported on Windows.
      #
      # @!method container_top
      # Engine API: GET /containers/{id}/top
      #
      # @param id [String] ID or name of the container
      # @param ps_args [String, nil] The arguments to pass to `ps`. For example,
      # `aux`
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- no such container
      # @raise [Docker::API::ServerError] 500 -- server error
      def container_top(id:, ps_args: nil, &block)
        connection.request(
          :get,
          "/containers/#{Path.escape(id)}/top",
          query: { "ps_args" => ps_args },
          expects: [200],
          operation: "container_top",
          &block
        )
      end

      # Unpause a container
      #
      # Resume a container which has been paused.
      #
      # @!method container_unpause
      # Engine API: POST /containers/{id}/unpause
      #
      # @param id [String] ID or name of the container
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- no such container
      # @raise [Docker::API::ServerError] 500 -- server error
      def container_unpause(id:, &block)
        connection.request(
          :post,
          "/containers/#{Path.escape(id)}/unpause",
          expects: [204],
          operation: "container_unpause",
          &block
        )
      end

      # Update a container
      #
      # Change various configuration options of a container without having to
      # recreate it.
      #
      # @!method container_update
      # Engine API: POST /containers/{id}/update
      #
      # @param id [String] ID or name of the container
      # @param body [Hash] (body parameter 'update' in the API specification)
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- no such container
      # @raise [Docker::API::ServerError] 500 -- server error
      def container_update(id:, body:, &block)
        connection.request(
          :post,
          "/containers/#{Path.escape(id)}/update",
          body: body,
          expects: [200],
          operation: "container_update",
          &block
        )
      end

      # Wait for a container
      #
      # Block until a container stops, then returns the exit code.
      #
      # @!method container_wait
      # Engine API: POST /containers/{id}/wait
      #
      # @param id [String] ID or name of the container
      # @param condition [String, nil] Wait until a container state reaches the
      # given condition.
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::BadRequest] 400 -- bad parameter
      # @raise [Docker::API::NotFound] 404 -- no such container
      # @raise [Docker::API::ServerError] 500 -- server error
      def container_wait(id:, condition: nil, &block)
        connection.request(
          :post,
          "/containers/#{Path.escape(id)}/wait",
          query: { "condition" => condition },
          expects: [200],
          operation: "container_wait",
          &block
        )
      end

      # Extract an archive of files or folders to a directory in a container
      #
      # Upload a tar archive to be extracted to a path in the filesystem of
      # container id. `path` parameter is asserted to be a directory. If it exists
      # as a file, 400 error will be returned with message "not a directory".
      #
      # @!method put_container_archive
      # Engine API: PUT /containers/{id}/archive
      #
      # @param id [String] ID or name of the container
      # @param path [String] Path to a directory in the container to extract the
      # archive’s contents into.
      # @param body [Hash] The input stream must be a tar archive compressed
      # with one of the following algorithms: `identity` (no compression),
      # `gzip`, `bzip2`, or `xz`. (body parameter 'inputStream' in the API
      # specification)
      # @param no_overwrite_dir_non_dir [String, nil] If `1`, `true`, or `True`
      # then it will be an error if unpacking the given content would cause an
      # existing directory to be replaced with a non-directory and vice... (sent
      # to the daemon as 'noOverwriteDirNonDir')
      # @param copy_uidgid [String, nil] If `1`, `true`, then it will copy
      # UID/GID maps to the dest file or dir (sent to the daemon as
      # 'copyUIDGID')
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::BadRequest] 400 -- Bad parameter
      # @raise [Docker::API::Forbidden] 403 -- Permission denied, the volume or
      # container rootfs is marked as read-only.
      # @raise [Docker::API::NotFound] 404 -- No such container or path does not
      # exist inside the container
      # @raise [Docker::API::ServerError] 500 -- Server error
      def put_container_archive(id:, path:, body:, no_overwrite_dir_non_dir: nil, copy_uidgid: nil, &block)
        connection.request(
          :put,
          "/containers/#{Path.escape(id)}/archive",
          query: {
            "path" => path,
            "noOverwriteDirNonDir" => no_overwrite_dir_non_dir,
            "copyUIDGID" => copy_uidgid,
          },
          body: body,
          expects: [200],
          operation: "put_container_archive",
          &block
        )
      end

      # Get image information from the registry
      #
      # Return image digest and platform information by contacting the registry.
      #
      # @!method distribution_inspect
      # Engine API: GET /distribution/{name}/json
      #
      # @param name [String] Image name or id
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::Unauthorized] 401 -- Failed authentication or no
      # image found
      # @raise [Docker::API::ServerError] 500 -- Server error
      def distribution_inspect(name:, &block)
        connection.request(
          :get,
          "/distribution/#{Path.escape(name)}/json",
          expects: [200],
          operation: "distribution_inspect",
          &block
        )
      end

      # Create an exec instance
      #
      # Run a command inside a running container.
      #
      # @!method container_exec
      # Engine API: POST /containers/{id}/exec
      #
      # @param id [String] ID or name of container
      # @param body [Hash] Exec configuration (body parameter 'execConfig' in
      # the API specification)
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- no such container
      # @raise [Docker::API::Conflict] 409 -- container is paused
      # @raise [Docker::API::ServerError] 500 -- Server error
      def container_exec(id:, body:, &block)
        connection.request(
          :post,
          "/containers/#{Path.escape(id)}/exec",
          body: body,
          expects: [201],
          operation: "container_exec",
          &block
        )
      end

      # Inspect an exec instance
      #
      # Return low-level information about an exec instance.
      #
      # @!method exec_inspect
      # Engine API: GET /exec/{id}/json
      #
      # @param id [String] Exec instance ID
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- No such exec instance
      # @raise [Docker::API::ServerError] 500 -- Server error
      def exec_inspect(id:, &block)
        connection.request(
          :get,
          "/exec/#{Path.escape(id)}/json",
          expects: [200],
          operation: "exec_inspect",
          &block
        )
      end

      # Resize an exec instance
      #
      # Resize the TTY session used by an exec instance. This endpoint only works
      # if `tty` was specified as part of creating and starting the exec instance.
      #
      # @!method exec_resize
      # Engine API: POST /exec/{id}/resize
      #
      # @param id [String] Exec instance ID
      # @param h [Integer] Height of the TTY session in characters
      # @param w [Integer] Width of the TTY session in characters
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::BadRequest] 400 -- bad parameter
      # @raise [Docker::API::NotFound] 404 -- No such exec instance
      # @raise [Docker::API::ServerError] 500 -- Server error
      def exec_resize(id:, h:, w:, &block)
        connection.request(
          :post,
          "/exec/#{Path.escape(id)}/resize",
          query: { "h" => h, "w" => w },
          expects: [200],
          operation: "exec_resize",
          &block
        )
      end

      # Start an exec instance
      #
      # Starts a previously set up exec instance. If detach is true, this endpoint
      # returns immediately after starting the command. Otherwise, it sets up an
      # interactive session with the command.
      #
      # @!method exec_start
      # Engine API: POST /exec/{id}/start
      #
      # @param id [String] Exec instance ID
      # @param body [Hash, nil] (body parameter 'execStartConfig' in the API
      # specification)
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- No such exec instance
      # @raise [Docker::API::Conflict] 409 -- Container is stopped or paused
      def exec_start(id:, body: nil, &block)
        connection.request(
          :post,
          "/exec/#{Path.escape(id)}/start",
          body: body,
          expects: [200],
          operation: "exec_start",
          &block
        )
      end

      # Delete builder cache
      #
      # @!method build_prune
      # Engine API: POST /build/prune
      #
      # @param reserved_space [Integer, nil] Amount of disk space in bytes to
      # keep for cache (sent to the daemon as 'reserved-space')
      # @param max_used_space [Integer, nil] Maximum amount of disk space
      # allowed to keep for cache (sent to the daemon as 'max-used-space')
      # @param min_free_space [Integer, nil] Target amount of free disk space
      # after pruning (sent to the daemon as 'min-free-space')
      # @param all [Boolean, nil] Remove all types of build cache
      # @param filters [String, nil] A JSON encoded value of the filters (a
      # `map[string][]string`) to process on the list of build cache objects.
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::ServerError] 500 -- Server error
      def build_prune(reserved_space: nil, max_used_space: nil, min_free_space: nil, all: nil, filters: nil, &block)
        connection.request(
          :post,
          "/build/prune",
          query: {
            "reserved-space" => reserved_space,
            "max-used-space" => max_used_space,
            "min-free-space" => min_free_space,
            "all" => all,
            "filters" => filters,
          },
          expects: [200],
          operation: "build_prune",
          &block
        )
      end

      # Get attestation statements for an image
      #
      # Return the in-toto attestation statements attached to the image for the
      # given platform. The daemon locates the attestation manifest(s) that
      # reference the matching platform image manifest, reads their statement
      # layers, and returns the verbatim statement JSON together with layer
      # metadata.
      #
      # @!method image_attestations
      # Engine API: GET /images/{name}/attestations
      #
      # @param name [String] Image name or id
      # @param platform [Array<String>, nil] JSON-encoded OCI platform to select
      # the image variant whose attestations to return. If omitted, the daemon's
      # default (host) platform is used.
      # @param type [Array<String>, nil] In-toto predicate type URI to filter
      # returned statements. May be repeated to accept any of several predicate
      # types. If omitted, all statements are returned.
      # @param statement [Boolean, nil] Include the verbatim in-toto statement
      # body in each returned entry. Defaults to false; when omitted or false,
      # only the descriptor and predicate type are returne...
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::BadRequest] 400 -- Bad parameter (e.g. malformed
      # `platform` value)
      # @raise [Docker::API::NotFound] 404 -- No such image, or no manifest
      # found for the requested platform
      # @raise [Docker::API::ServerError] 500 -- Server error
      # @raise [Docker::API::ServerError] 501 -- The daemon's image backend does
      # not support attestations. This is returned by the legacy (...
      def image_attestations(name:, platform: nil, type: nil, statement: nil, &block)
        connection.request(
          :get,
          "/images/#{Path.escape(name)}/attestations",
          query: { "platform" => platform, "type" => type, "statement" => statement },
          expects: [200],
          operation: "image_attestations",
          &block
        )
      end

      # Build an image
      #
      # Build an image from a tar archive with a `Dockerfile` in it.
      #
      # @!method image_build
      # Engine API: POST /build
      #
      # @param dockerfile [String, nil] Path within the build context to the
      # `Dockerfile`. This is ignored if `remote` is specified and points to an
      # external `Dockerfile`.
      # @param t [String, nil] A name and optional tag to apply to the image in
      # the `name:tag` format. If you omit the tag the default `latest` value is
      # assumed. You can provide several `t` p...
      # @param extrahosts [String, nil] Extra hosts to add to /etc/hosts
      # @param remote [String, nil] A Git repository URI or HTTP/HTTPS context
      # URI. If the URI points to a single text file, the file’s contents are
      # placed into a file called `Dockerfile` and the...
      # @param q [Boolean, nil] Suppress verbose build output.
      # @param nocache [Boolean, nil] Do not use the cache when building the
      # image.
      # @param cachefrom [String, nil] JSON array of images used for build cache
      # resolution.
      # @param pull [String, nil] Attempt to pull the image even if an older
      # image exists locally.
      # @param rm [Boolean, nil] Remove intermediate containers after a
      # successful build.
      # @param forcerm [Boolean, nil] Always remove intermediate containers,
      # even upon failure.
      # @param memory [Integer, nil] Set memory limit for build.
      # @param memswap [Integer, nil] Total memory (memory + swap). Set as `-1`
      # to disable swap.
      # @param cpushares [Integer, nil] CPU shares (relative weight).
      # @param cpusetcpus [String, nil] CPUs in which to allow execution (e.g.,
      # `0-3`, `0,1`).
      # @param cpuperiod [Integer, nil] The length of a CPU period in
      # microseconds.
      # @param cpuquota [Integer, nil] Microseconds of CPU time that the
      # container can get in a CPU period.
      # @param buildargs [String, nil] JSON map of string pairs for build-time
      # variables. Users pass these values at build-time. Docker uses the
      # buildargs as the environment context for commands run...
      # @param shmsize [Integer, nil] Size of `/dev/shm` in bytes. The size must
      # be greater than 0. If omitted the system uses 64MB.
      # @param squash [Boolean, nil] Squash the resulting images layers into a
      # single layer. *(Experimental release only.)*
      # @param labels [String, nil] Arbitrary key/value labels to set on the
      # image, as a JSON map of string pairs.
      # @param networkmode [String, nil] Sets the networking mode for the run
      # commands during build. Supported standard values are: `bridge`, `host`,
      # `none`, and `container:<name|id>`. Any other value...
      # @param platform [String, nil] Platform in the format os[/arch[/variant]]
      # @param target [String, nil] Target build stage
      # @param outputs [String, nil] BuildKit output configuration in the format
      # of a stringified JSON array of objects. Each object must have two
      # top-level properties: `Type` and `Attrs`. The `Typ...
      # @param version [String, nil] Version of the builder backend to use.
      # @param content_type [String, nil] (sent to the daemon as 'Content-type')
      # @param x_registry_config [String, nil] This is a base64-encoded JSON
      # object with auth configurations for multiple registries that a build may
      # refer to. (sent to the daemon as 'X-Registry-Config')
      # @param body [Hash, nil] A tar archive compressed with one of the
      # following algorithms: identity (no compression), gzip, bzip2, xz. (body
      # parameter 'inputStream' in the API specification)
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::BadRequest] 400 -- Bad parameter
      # @raise [Docker::API::ServerError] 500 -- server error
      def image_build(
        dockerfile: nil,
        t: nil,
        extrahosts: nil,
        remote: nil,
        q: nil,
        nocache: nil,
        cachefrom: nil,
        pull: nil,
        rm: nil,
        forcerm: nil,
        memory: nil,
        memswap: nil,
        cpushares: nil,
        cpusetcpus: nil,
        cpuperiod: nil,
        cpuquota: nil,
        buildargs: nil,
        shmsize: nil,
        squash: nil,
        labels: nil,
        networkmode: nil,
        platform: nil,
        target: nil,
        outputs: nil,
        version: nil,
        content_type: nil,
        x_registry_config: nil,
        body: nil,
        &block
      )
        connection.request(
          :post,
          "/build",
          query: {
            "dockerfile" => dockerfile,
            "t" => t,
            "extrahosts" => extrahosts,
            "remote" => remote,
            "q" => q,
            "nocache" => nocache,
            "cachefrom" => cachefrom,
            "pull" => pull,
            "rm" => rm,
            "forcerm" => forcerm,
            "memory" => memory,
            "memswap" => memswap,
            "cpushares" => cpushares,
            "cpusetcpus" => cpusetcpus,
            "cpuperiod" => cpuperiod,
            "cpuquota" => cpuquota,
            "buildargs" => buildargs,
            "shmsize" => shmsize,
            "squash" => squash,
            "labels" => labels,
            "networkmode" => networkmode,
            "platform" => platform,
            "target" => target,
            "outputs" => outputs,
            "version" => version,
          },
          headers: { "Content-type" => content_type, "X-Registry-Config" => x_registry_config }.compact,
          body: body,
          expects: [200],
          operation: "image_build",
          &block
        )
      end

      # Create a new image from a container
      #
      # @!method image_commit
      # Engine API: POST /commit
      #
      # @param container [String, nil] The ID or name of the container to commit
      # @param repo [String, nil] Repository name for the created image
      # @param tag [String, nil] Tag name for the create image
      # @param comment [String, nil] Commit message
      # @param author [String, nil] Author of the image (e.g., `John Hannibal
      # Smith <hannibal@a-team.com>`)
      # @param pause [Boolean, nil] Whether to pause the container before
      # committing
      # @param changes [String, nil] `Dockerfile` instructions to apply while
      # committing
      # @param body [Hash, nil] The container configuration (body parameter
      # 'containerConfig' in the API specification)
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- no such container
      # @raise [Docker::API::ServerError] 500 -- server error
      def image_commit(
        container: nil,
        repo: nil,
        tag: nil,
        comment: nil,
        author: nil,
        pause: nil,
        changes: nil,
        body: nil,
        &block
      )
        connection.request(
          :post,
          "/commit",
          query: {
            "container" => container,
            "repo" => repo,
            "tag" => tag,
            "comment" => comment,
            "author" => author,
            "pause" => pause,
            "changes" => changes,
          },
          body: body,
          expects: [201],
          operation: "image_commit",
          &block
        )
      end

      # Create an image
      #
      # Pull or import an image.
      #
      # @!method image_create
      # Engine API: POST /images/create
      #
      # @param from_image [String, nil] Name of the image to pull. If the name
      # includes a tag or digest, specific behavior applies: (sent to the daemon
      # as 'fromImage')
      # @param from_src [String, nil] Source to import. The value may be a URL
      # from which the image can be retrieved or `-` to read the image from the
      # request body. This parameter may only be used w... (sent to the daemon
      # as 'fromSrc')
      # @param repo [String, nil] Repository name given to an image when it is
      # imported. The repo may include a tag. This parameter may only be used
      # when importing an image.
      # @param tag [String, nil] Tag or digest. If empty when pulling an image,
      # this causes all tags for the given image to be pulled.
      # @param message [String, nil] Set commit message for imported image.
      # @param changes [Array<String>, nil] Apply `Dockerfile` instructions to
      # the image that is created, for example: `changes=ENV DEBUG=true`. Note
      # that `ENV DEBUG=true` should be URI component encoded.
      # @param platform [String, nil] Platform in the format
      # os[/arch[/variant]].
      # @param x_registry_auth [String, nil] A base64url-encoded auth
      # configuration. (sent to the daemon as 'X-Registry-Auth')
      # @param body [Hash, nil] Image content if the value `-` has been
      # specified in fromSrc query parameter (body parameter 'inputImage' in the
      # API specification)
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- repository does not exist or no
      # read access
      # @raise [Docker::API::ServerError] 500 -- server error
      def image_create(
        from_image: nil,
        from_src: nil,
        repo: nil,
        tag: nil,
        message: nil,
        changes: nil,
        platform: nil,
        x_registry_auth: nil,
        body: nil,
        &block
      )
        connection.request(
          :post,
          "/images/create",
          query: {
            "fromImage" => from_image,
            "fromSrc" => from_src,
            "repo" => repo,
            "tag" => tag,
            "message" => message,
            "changes" => changes,
            "platform" => platform,
          },
          headers: { "X-Registry-Auth" => x_registry_auth }.compact,
          body: body,
          expects: [200],
          operation: "image_create",
          &block
        )
      end

      # Remove an image
      #
      # Remove an image, along with any untagged parent images that were
      # referenced by that image.
      #
      # @!method image_delete
      # Engine API: DELETE /images/{name}
      #
      # @param name [String] Image name or ID
      # @param force [Boolean, nil] Remove the image even if it is being used by
      # stopped containers or has other tags
      # @param noprune [Boolean, nil] Do not delete untagged parent images
      # @param platforms [Array<String>, nil] Select platform-specific content
      # to delete. Multiple values are accepted. Each platform is a OCI platform
      # encoded as a JSON string.
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- No such image
      # @raise [Docker::API::Conflict] 409 -- Conflict
      # @raise [Docker::API::ServerError] 500 -- Server error
      def image_delete(name:, force: nil, noprune: nil, platforms: nil, &block)
        connection.request(
          :delete,
          "/images/#{Path.escape(name)}",
          query: { "force" => force, "noprune" => noprune, "platforms" => platforms },
          expects: [200],
          operation: "image_delete",
          &block
        )
      end

      # Export an image
      #
      # Get a tarball containing all images and metadata for a repository.
      #
      # @!method image_get
      # Engine API: GET /images/{name}/get
      #
      # @param name [String] Image name or ID
      # @param platform [Array<String>, nil] JSON encoded OCI platform
      # describing a platform which will be used to select a platform-specific
      # image to be saved if the image is multi-platform. If not provid...
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::ServerError] 500 -- server error
      def image_get(name:, platform: nil, &block)
        connection.request(
          :get,
          "/images/#{Path.escape(name)}/get",
          query: { "platform" => platform },
          expects: [200],
          operation: "image_get",
          &block
        )
      end

      # Export several images
      #
      # Get a tarball containing all images and metadata for several image
      # repositories.
      #
      # @!method image_get_all
      # Engine API: GET /images/get
      #
      # @param names [Array<String>, nil] Image names to filter by
      # @param platform [Array<String>, nil] JSON encoded OCI platform(s) which
      # will be used to select the platform-specific image(s) to be saved if the
      # image is multi-platform. If not provided, the full m...
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::ServerError] 500 -- server error
      def image_get_all(names: nil, platform: nil, &block)
        connection.request(
          :get,
          "/images/get",
          query: { "names" => names, "platform" => platform },
          expects: [200],
          operation: "image_get_all",
          &block
        )
      end

      # Get the history of an image
      #
      # Return parent layers of an image.
      #
      # @!method image_history
      # Engine API: GET /images/{name}/history
      #
      # @param name [String] Image name or ID
      # @param platform [String, nil] JSON-encoded OCI platform to select the
      # platform-variant. If omitted, it defaults to any locally available
      # platform, prioritizing the daemon's host platform.
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- No such image
      # @raise [Docker::API::ServerError] 500 -- Server error
      def image_history(name:, platform: nil, &block)
        connection.request(
          :get,
          "/images/#{Path.escape(name)}/history",
          query: { "platform" => platform },
          expects: [200],
          operation: "image_history",
          &block
        )
      end

      # Inspect an image
      #
      # Return low-level information about an image.
      #
      # @!method image_inspect
      # Engine API: GET /images/{name}/json
      #
      # @param name [String] Image name or id
      # @param manifests [Boolean, nil] Include Manifests in the image summary.
      # @param platform [String, nil] JSON-encoded OCI platform to select the
      # platform-variant. If omitted, it defaults to any locally available
      # platform, prioritizing the daemon's host platform.
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- No such image
      # @raise [Docker::API::ServerError] 500 -- Server error
      def image_inspect(name:, manifests: nil, platform: nil, &block)
        connection.request(
          :get,
          "/images/#{Path.escape(name)}/json",
          query: { "manifests" => manifests, "platform" => platform },
          expects: [200],
          operation: "image_inspect",
          &block
        )
      end

      # List Images
      #
      # Returns a list of images on the server. Note that it uses a different,
      # smaller representation of an image than inspecting a single image.
      #
      # @!method image_list
      # Engine API: GET /images/json
      #
      # @param all [Boolean, nil] Show all images. Only images from a final
      # layer (no children) are shown by default.
      # @param filters [String, nil] A JSON encoded value of the filters (a
      # `map[string][]string`) to process on the images list.
      # @param shared_size [Boolean, nil] Compute and show shared size as a
      # `SharedSize` field on each image. (sent to the daemon as 'shared-size')
      # @param digests [Boolean, nil] Show digest information as a `RepoDigests`
      # field on each image.
      # @param manifests [Boolean, nil] Include `Manifests` in the image
      # summary.
      # @param identity [Boolean, nil] Include `Identity` in each manifest
      # summary. Requires `manifests=1`.
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::ServerError] 500 -- server error
      def image_list(all: nil, filters: nil, shared_size: nil, digests: nil, manifests: nil, identity: nil, &block)
        connection.request(
          :get,
          "/images/json",
          query: {
            "all" => all,
            "filters" => filters,
            "shared-size" => shared_size,
            "digests" => digests,
            "manifests" => manifests,
            "identity" => identity,
          },
          expects: [200],
          operation: "image_list",
          &block
        )
      end

      # Import images
      #
      # Load a set of images and tags into a repository.
      #
      # @!method image_load
      # Engine API: POST /images/load
      #
      # @param quiet [Boolean, nil] Suppress progress details during load.
      # @param platform [Array<String>, nil] JSON encoded OCI platform(s) which
      # will be used to select the platform-specific image(s) to load if the
      # image is multi-platform. If not provided, the full multi...
      # @param body [Hash, nil] Tar archive containing images (body parameter
      # 'imagesTarball' in the API specification)
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::ServerError] 500 -- server error
      def image_load(quiet: nil, platform: nil, body: nil, &block)
        connection.request(
          :post,
          "/images/load",
          query: { "quiet" => quiet, "platform" => platform },
          body: body,
          expects: [200],
          operation: "image_load",
          &block
        )
      end

      # Delete unused images
      #
      # @!method image_prune
      # Engine API: POST /images/prune
      #
      # @param filters [String, nil] Filters to process on the prune list,
      # encoded as JSON (a `map[string][]string`). Available filters:
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::ServerError] 500 -- Server error
      def image_prune(filters: nil, &block)
        connection.request(
          :post,
          "/images/prune",
          query: { "filters" => filters },
          expects: [200],
          operation: "image_prune",
          &block
        )
      end

      # Push an image
      #
      # Push an image to a registry.
      #
      # @!method image_push
      # Engine API: POST /images/{name}/push
      #
      # @param name [String] Name of the image to push. For example,
      # `registry.example.com/myimage`. The image must be present in the local
      # image store with the same name.
      # @param x_registry_auth [String] A base64url-encoded auth configuration.
      # (sent to the daemon as 'X-Registry-Auth')
      # @param tag [String, nil] Tag of the image to push. For example,
      # `latest`. If no tag is provided, all tags of the given image that are
      # present in the local image store are pushed.
      # @param platform [String, nil] JSON-encoded OCI platform to select the
      # platform-variant to push. If not provided, all available variants will
      # attempt to be pushed.
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- No such image
      # @raise [Docker::API::ServerError] 500 -- Server error
      def image_push(name:, x_registry_auth:, tag: nil, platform: nil, &block)
        connection.request(
          :post,
          "/images/#{Path.escape(name)}/push",
          query: { "tag" => tag, "platform" => platform },
          headers: { "X-Registry-Auth" => x_registry_auth }.compact,
          expects: [200],
          operation: "image_push",
          &block
        )
      end

      # Search images
      #
      # Search for an image on Docker Hub.
      #
      # @!method image_search
      # Engine API: GET /images/search
      #
      # @param term [String] Term to search
      # @param limit [Integer, nil] Maximum number of results to return
      # @param filters [String, nil] A JSON encoded value of the filters (a
      # `map[string][]string`) to process on the images list. Available filters:
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::ServerError] 500 -- Server error
      def image_search(term:, limit: nil, filters: nil, &block)
        connection.request(
          :get,
          "/images/search",
          query: { "term" => term, "limit" => limit, "filters" => filters },
          expects: [200],
          operation: "image_search",
          &block
        )
      end

      # Tag an image
      #
      # Create a tag that refers to a source image.
      #
      # @!method image_tag
      # Engine API: POST /images/{name}/tag
      #
      # @param name [String] Image name or ID to tag.
      # @param repo [String, nil] The repository to tag in. For example,
      # `someuser/someimage`.
      # @param tag [String, nil] The name of the new tag.
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::BadRequest] 400 -- Bad parameter
      # @raise [Docker::API::NotFound] 404 -- No such image
      # @raise [Docker::API::Conflict] 409 -- Conflict
      # @raise [Docker::API::ServerError] 500 -- Server error
      def image_tag(name:, repo: nil, tag: nil, &block)
        connection.request(
          :post,
          "/images/#{Path.escape(name)}/tag",
          query: { "repo" => repo, "tag" => tag },
          expects: [201],
          operation: "image_tag",
          &block
        )
      end

      # Connect a container to a network
      #
      # The network must be either a local-scoped network or a swarm-scoped
      # network with the `attachable` option set. A network cannot be re-attached
      # to a running container
      #
      # @!method network_connect
      # Engine API: POST /networks/{id}/connect
      #
      # @param id [String] Network ID or name
      # @param body [Hash] (body parameter 'container' in the API specification)
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::BadRequest] 400 -- bad parameter
      # @raise [Docker::API::Forbidden] 403 -- Operation forbidden
      # @raise [Docker::API::NotFound] 404 -- Network or container not found
      # @raise [Docker::API::ServerError] 500 -- Server error
      def network_connect(id:, body:, &block)
        connection.request(
          :post,
          "/networks/#{Path.escape(id)}/connect",
          body: body,
          expects: [200],
          operation: "network_connect",
          &block
        )
      end

      # Create a network
      #
      # @!method network_create
      # Engine API: POST /networks/create
      #
      # @param body [Hash] Network configuration (body parameter 'networkConfig'
      # in the API specification)
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::BadRequest] 400 -- bad parameter
      # @raise [Docker::API::Forbidden] 403 -- Forbidden operation. This happens
      # when trying to create a network named after a pre-define...
      # @raise [Docker::API::NotFound] 404 -- plugin not found
      # @raise [Docker::API::ServerError] 500 -- Server error
      def network_create(body:, &block)
        connection.request(
          :post,
          "/networks/create",
          body: body,
          expects: [201],
          operation: "network_create",
          &block
        )
      end

      # Remove a network
      #
      # @!method network_delete
      # Engine API: DELETE /networks/{id}
      #
      # @param id [String] Network ID or name
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::Forbidden] 403 -- operation not supported for
      # pre-defined networks
      # @raise [Docker::API::NotFound] 404 -- no such network
      # @raise [Docker::API::ServerError] 500 -- Server error
      def network_delete(id:, &block)
        connection.request(
          :delete,
          "/networks/#{Path.escape(id)}",
          expects: [204],
          operation: "network_delete",
          &block
        )
      end

      # Disconnect a container from a network
      #
      # @!method network_disconnect
      # Engine API: POST /networks/{id}/disconnect
      #
      # @param id [String] Network ID or name
      # @param body [Hash] (body parameter 'container' in the API specification)
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::Forbidden] 403 -- Operation not supported for swarm
      # scoped networks
      # @raise [Docker::API::NotFound] 404 -- Network or container not found
      # @raise [Docker::API::ServerError] 500 -- Server error
      def network_disconnect(id:, body:, &block)
        connection.request(
          :post,
          "/networks/#{Path.escape(id)}/disconnect",
          body: body,
          expects: [200],
          operation: "network_disconnect",
          &block
        )
      end

      # Inspect a network
      #
      # @!method network_inspect
      # Engine API: GET /networks/{id}
      #
      # @param id [String] Network ID or name
      # @param verbose [Boolean, nil] Detailed inspect output for
      # troubleshooting
      # @param scope [String, nil] Filter the network by scope (swarm, global,
      # or local)
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- Network not found
      # @raise [Docker::API::ServerError] 500 -- Server error
      def network_inspect(id:, verbose: nil, scope: nil, &block)
        connection.request(
          :get,
          "/networks/#{Path.escape(id)}",
          query: { "verbose" => verbose, "scope" => scope },
          expects: [200],
          operation: "network_inspect",
          &block
        )
      end

      # List networks
      #
      # Returns a list of networks. For details on the format, see the [network
      # inspect endpoint](#operation/NetworkInspect).
      #
      # @!method network_list
      # Engine API: GET /networks
      #
      # @param filters [String, nil] JSON encoded value of the filters (a
      # `map[string][]string`) to process on the networks list.
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::ServerError] 500 -- Server error
      def network_list(filters: nil, &block)
        connection.request(
          :get,
          "/networks",
          query: { "filters" => filters },
          expects: [200],
          operation: "network_list",
          &block
        )
      end

      # Delete unused networks
      #
      # @!method network_prune
      # Engine API: POST /networks/prune
      #
      # @param filters [String, nil] Filters to process on the prune list,
      # encoded as JSON (a `map[string][]string`).
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::ServerError] 500 -- Server error
      def network_prune(filters: nil, &block)
        connection.request(
          :post,
          "/networks/prune",
          query: { "filters" => filters },
          expects: [200],
          operation: "network_prune",
          &block
        )
      end

      # Delete a node
      #
      # @!method node_delete
      # Engine API: DELETE /nodes/{id}
      #
      # @param id [String] The ID or name of the node
      # @param force [Boolean, nil] Force remove a node from the swarm
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- no such node
      # @raise [Docker::API::ServerError] 500 -- server error
      # @raise [Docker::API::ServerError] 503 -- node is not part of a swarm
      def node_delete(id:, force: nil, &block)
        connection.request(
          :delete,
          "/nodes/#{Path.escape(id)}",
          query: { "force" => force },
          expects: [200],
          operation: "node_delete",
          &block
        )
      end

      # Inspect a node
      #
      # @!method node_inspect
      # Engine API: GET /nodes/{id}
      #
      # @param id [String] The ID or name of the node
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- no such node
      # @raise [Docker::API::ServerError] 500 -- server error
      # @raise [Docker::API::ServerError] 503 -- node is not part of a swarm
      def node_inspect(id:, &block)
        connection.request(
          :get,
          "/nodes/#{Path.escape(id)}",
          expects: [200],
          operation: "node_inspect",
          &block
        )
      end

      # List nodes
      #
      # @!method node_list
      # Engine API: GET /nodes
      #
      # @param filters [String, nil] Filters to process on the nodes list,
      # encoded as JSON (a `map[string][]string`).
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::ServerError] 500 -- server error
      # @raise [Docker::API::ServerError] 503 -- node is not part of a swarm
      def node_list(filters: nil, &block)
        connection.request(
          :get,
          "/nodes",
          query: { "filters" => filters },
          expects: [200],
          operation: "node_list",
          &block
        )
      end

      # Update a node
      #
      # @!method node_update
      # Engine API: POST /nodes/{id}/update
      #
      # @param id [String] The ID of the node
      # @param version [Integer] The version number of the node object being
      # updated. This is required to avoid conflicting writes.
      # @param body [Hash, nil] (body parameter 'body' in the API specification)
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::BadRequest] 400 -- bad parameter
      # @raise [Docker::API::NotFound] 404 -- no such node
      # @raise [Docker::API::ServerError] 500 -- server error
      # @raise [Docker::API::ServerError] 503 -- node is not part of a swarm
      def node_update(id:, version:, body: nil, &block)
        connection.request(
          :post,
          "/nodes/#{Path.escape(id)}/update",
          query: { "version" => version },
          body: body,
          expects: [200],
          operation: "node_update",
          &block
        )
      end

      # Get plugin privileges
      #
      # @!method get_plugin_privileges
      # Engine API: GET /plugins/privileges
      #
      # @param remote [String] The name of the plugin. The `:latest` tag is
      # optional, and is the default if omitted.
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::ServerError] 500 -- server error
      def get_plugin_privileges(remote:, &block)
        connection.request(
          :get,
          "/plugins/privileges",
          query: { "remote" => remote },
          expects: [200],
          operation: "get_plugin_privileges",
          &block
        )
      end

      # Create a plugin
      #
      # @!method plugin_create
      # Engine API: POST /plugins/create
      #
      # @param name [String] The name of the plugin. The `:latest` tag is
      # optional, and is the default if omitted.
      # @param body [Hash, nil] Path to tar containing plugin rootfs and
      # manifest (body parameter 'tarContext' in the API specification)
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::ServerError] 500 -- server error
      def plugin_create(name:, body: nil, &block)
        connection.request(
          :post,
          "/plugins/create",
          query: { "name" => name },
          body: body,
          expects: [204],
          operation: "plugin_create",
          &block
        )
      end

      # Remove a plugin
      #
      # @!method plugin_delete
      # Engine API: DELETE /plugins/{name}
      #
      # @param name [String] The name of the plugin. The `:latest` tag is
      # optional, and is the default if omitted.
      # @param force [Boolean, nil] Disable the plugin before removing. This may
      # result in issues if the plugin is in use by a container.
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- plugin is not installed
      # @raise [Docker::API::ServerError] 500 -- server error
      def plugin_delete(name:, force: nil, &block)
        connection.request(
          :delete,
          "/plugins/#{Path.escape(name)}",
          query: { "force" => force },
          expects: [200],
          operation: "plugin_delete",
          &block
        )
      end

      # Disable a plugin
      #
      # @!method plugin_disable
      # Engine API: POST /plugins/{name}/disable
      #
      # @param name [String] The name of the plugin. The `:latest` tag is
      # optional, and is the default if omitted.
      # @param force [Boolean, nil] Force disable a plugin even if still in use.
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- plugin is not installed
      # @raise [Docker::API::ServerError] 500 -- server error
      def plugin_disable(name:, force: nil, &block)
        connection.request(
          :post,
          "/plugins/#{Path.escape(name)}/disable",
          query: { "force" => force },
          expects: [200],
          operation: "plugin_disable",
          &block
        )
      end

      # Enable a plugin
      #
      # @!method plugin_enable
      # Engine API: POST /plugins/{name}/enable
      #
      # @param name [String] The name of the plugin. The `:latest` tag is
      # optional, and is the default if omitted.
      # @param timeout [Integer, nil] Set the HTTP client timeout (in seconds)
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- plugin is not installed
      # @raise [Docker::API::ServerError] 500 -- server error
      def plugin_enable(name:, timeout: nil, &block)
        connection.request(
          :post,
          "/plugins/#{Path.escape(name)}/enable",
          query: { "timeout" => timeout },
          expects: [200],
          operation: "plugin_enable",
          &block
        )
      end

      # Inspect a plugin
      #
      # @!method plugin_inspect
      # Engine API: GET /plugins/{name}/json
      #
      # @param name [String] The name of the plugin. The `:latest` tag is
      # optional, and is the default if omitted.
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- plugin is not installed
      # @raise [Docker::API::ServerError] 500 -- server error
      def plugin_inspect(name:, &block)
        connection.request(
          :get,
          "/plugins/#{Path.escape(name)}/json",
          expects: [200],
          operation: "plugin_inspect",
          &block
        )
      end

      # List plugins
      #
      # Returns information about installed plugins.
      #
      # @!method plugin_list
      # Engine API: GET /plugins
      #
      # @param filters [String, nil] A JSON encoded value of the filters (a
      # `map[string][]string`) to process on the plugin list.
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::ServerError] 500 -- Server error
      def plugin_list(filters: nil, &block)
        connection.request(
          :get,
          "/plugins",
          query: { "filters" => filters },
          expects: [200],
          operation: "plugin_list",
          &block
        )
      end

      # Install a plugin
      #
      # Pulls and installs a plugin. After the plugin is installed, it can be
      # enabled using the [`POST /plugins/{name}/enable`
      # endpoint](#operation/PostPluginsEnable).
      #
      # @!method plugin_pull
      # Engine API: POST /plugins/pull
      #
      # @param remote [String] Remote reference for plugin to install.
      # @param name [String, nil] Local name for the pulled plugin.
      # @param x_registry_auth [String, nil] A base64url-encoded auth
      # configuration to use when pulling a plugin from a registry. (sent to the
      # daemon as 'X-Registry-Auth')
      # @param body [Hash, nil] (body parameter 'body' in the API specification)
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::ServerError] 500 -- server error
      def plugin_pull(remote:, name: nil, x_registry_auth: nil, body: nil, &block)
        connection.request(
          :post,
          "/plugins/pull",
          query: { "remote" => remote, "name" => name },
          headers: { "X-Registry-Auth" => x_registry_auth }.compact,
          body: body,
          expects: [204],
          operation: "plugin_pull",
          &block
        )
      end

      # Push a plugin
      #
      # Push a plugin to the registry.
      #
      # @!method plugin_push
      # Engine API: POST /plugins/{name}/push
      #
      # @param name [String] The name of the plugin. The `:latest` tag is
      # optional, and is the default if omitted.
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- plugin not installed
      # @raise [Docker::API::ServerError] 500 -- server error
      def plugin_push(name:, &block)
        connection.request(
          :post,
          "/plugins/#{Path.escape(name)}/push",
          expects: [200],
          operation: "plugin_push",
          &block
        )
      end

      # Configure a plugin
      #
      # @!method plugin_set
      # Engine API: POST /plugins/{name}/set
      #
      # @param name [String] The name of the plugin. The `:latest` tag is
      # optional, and is the default if omitted.
      # @param body [Hash, nil] (body parameter 'body' in the API specification)
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- Plugin not installed
      # @raise [Docker::API::ServerError] 500 -- Server error
      def plugin_set(name:, body: nil, &block)
        connection.request(
          :post,
          "/plugins/#{Path.escape(name)}/set",
          body: body,
          expects: [204],
          operation: "plugin_set",
          &block
        )
      end

      # Upgrade a plugin
      #
      # @!method plugin_upgrade
      # Engine API: POST /plugins/{name}/upgrade
      #
      # @param name [String] The name of the plugin. The `:latest` tag is
      # optional, and is the default if omitted.
      # @param remote [String] Remote reference to upgrade to.
      # @param x_registry_auth [String, nil] A base64url-encoded auth
      # configuration to use when pulling a plugin from a registry. (sent to the
      # daemon as 'X-Registry-Auth')
      # @param body [Hash, nil] (body parameter 'body' in the API specification)
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- plugin not installed
      # @raise [Docker::API::ServerError] 500 -- server error
      def plugin_upgrade(name:, remote:, x_registry_auth: nil, body: nil, &block)
        connection.request(
          :post,
          "/plugins/#{Path.escape(name)}/upgrade",
          query: { "remote" => remote },
          headers: { "X-Registry-Auth" => x_registry_auth }.compact,
          body: body,
          expects: [204],
          operation: "plugin_upgrade",
          &block
        )
      end

      # Create a secret
      #
      # @!method secret_create
      # Engine API: POST /secrets/create
      #
      # @param body [Hash, nil] (body parameter 'body' in the API specification)
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::Conflict] 409 -- name conflicts with an existing
      # object
      # @raise [Docker::API::ServerError] 500 -- server error
      # @raise [Docker::API::ServerError] 503 -- node is not part of a swarm
      def secret_create(body: nil, &block)
        connection.request(
          :post,
          "/secrets/create",
          body: body,
          expects: [201],
          operation: "secret_create",
          &block
        )
      end

      # Delete a secret
      #
      # @!method secret_delete
      # Engine API: DELETE /secrets/{id}
      #
      # @param id [String] ID of the secret
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- secret not found
      # @raise [Docker::API::ServerError] 500 -- server error
      # @raise [Docker::API::ServerError] 503 -- node is not part of a swarm
      def secret_delete(id:, &block)
        connection.request(
          :delete,
          "/secrets/#{Path.escape(id)}",
          expects: [204],
          operation: "secret_delete",
          &block
        )
      end

      # Inspect a secret
      #
      # @!method secret_inspect
      # Engine API: GET /secrets/{id}
      #
      # @param id [String] ID of the secret
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- secret not found
      # @raise [Docker::API::ServerError] 500 -- server error
      # @raise [Docker::API::ServerError] 503 -- node is not part of a swarm
      def secret_inspect(id:, &block)
        connection.request(
          :get,
          "/secrets/#{Path.escape(id)}",
          expects: [200],
          operation: "secret_inspect",
          &block
        )
      end

      # List secrets
      #
      # @!method secret_list
      # Engine API: GET /secrets
      #
      # @param filters [String, nil] A JSON encoded value of the filters (a
      # `map[string][]string`) to process on the secrets list.
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::ServerError] 500 -- server error
      # @raise [Docker::API::ServerError] 503 -- node is not part of a swarm
      def secret_list(filters: nil, &block)
        connection.request(
          :get,
          "/secrets",
          query: { "filters" => filters },
          expects: [200],
          operation: "secret_list",
          &block
        )
      end

      # Update a Secret
      #
      # @!method secret_update
      # Engine API: POST /secrets/{id}/update
      #
      # @param id [String] The ID or name of the secret
      # @param version [Integer] The version number of the secret object being
      # updated. This is required to avoid conflicting writes.
      # @param body [Hash, nil] The spec of the secret to update. Currently,
      # only the Labels field can be updated. All other fields must remain
      # unchanged from the [SecretInspect endpoint](#ope... (body parameter
      # 'body' in the API specification)
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::BadRequest] 400 -- bad parameter
      # @raise [Docker::API::NotFound] 404 -- no such secret
      # @raise [Docker::API::ServerError] 500 -- server error
      # @raise [Docker::API::ServerError] 503 -- node is not part of a swarm
      def secret_update(id:, version:, body: nil, &block)
        connection.request(
          :post,
          "/secrets/#{Path.escape(id)}/update",
          query: { "version" => version },
          body: body,
          expects: [200],
          operation: "secret_update",
          &block
        )
      end

      # Create a service
      #
      # @!method service_create
      # Engine API: POST /services/create
      #
      # @param body [Hash] (body parameter 'body' in the API specification)
      # @param x_registry_auth [String, nil] A base64url-encoded auth
      # configuration for pulling from private registries. (sent to the daemon
      # as 'X-Registry-Auth')
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::BadRequest] 400 -- bad parameter
      # @raise [Docker::API::Forbidden] 403 -- network is not eligible for
      # services
      # @raise [Docker::API::Conflict] 409 -- name conflicts with an existing
      # service
      # @raise [Docker::API::ServerError] 500 -- server error
      # @raise [Docker::API::ServerError] 503 -- node is not part of a swarm
      def service_create(body:, x_registry_auth: nil, &block)
        connection.request(
          :post,
          "/services/create",
          headers: { "X-Registry-Auth" => x_registry_auth }.compact,
          body: body,
          expects: [201],
          operation: "service_create",
          &block
        )
      end

      # Delete a service
      #
      # @!method service_delete
      # Engine API: DELETE /services/{id}
      #
      # @param id [String] ID or name of service.
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- no such service
      # @raise [Docker::API::ServerError] 500 -- server error
      # @raise [Docker::API::ServerError] 503 -- node is not part of a swarm
      def service_delete(id:, &block)
        connection.request(
          :delete,
          "/services/#{Path.escape(id)}",
          expects: [200],
          operation: "service_delete",
          &block
        )
      end

      # Inspect a service
      #
      # @!method service_inspect
      # Engine API: GET /services/{id}
      #
      # @param id [String] ID or name of service.
      # @param insert_defaults [Boolean, nil] Fill empty fields with default
      # values. (sent to the daemon as 'insertDefaults')
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- no such service
      # @raise [Docker::API::ServerError] 500 -- server error
      # @raise [Docker::API::ServerError] 503 -- node is not part of a swarm
      def service_inspect(id:, insert_defaults: nil, &block)
        connection.request(
          :get,
          "/services/#{Path.escape(id)}",
          query: { "insertDefaults" => insert_defaults },
          expects: [200],
          operation: "service_inspect",
          &block
        )
      end

      # List services
      #
      # @!method service_list
      # Engine API: GET /services
      #
      # @param filters [String, nil] A JSON encoded value of the filters (a
      # `map[string][]string`) to process on the services list.
      # @param status [Boolean, nil] Include service status, with count of
      # running and desired tasks.
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::ServerError] 500 -- server error
      # @raise [Docker::API::ServerError] 503 -- node is not part of a swarm
      def service_list(filters: nil, status: nil, &block)
        connection.request(
          :get,
          "/services",
          query: { "filters" => filters, "status" => status },
          expects: [200],
          operation: "service_list",
          &block
        )
      end

      # Get service logs
      #
      # Get `stdout` and `stderr` logs from a service. See also
      # [`/containers/{id}/logs`](#operation/ContainerLogs).
      #
      # @!method service_logs
      # Engine API: GET /services/{id}/logs
      #
      # @param id [String] ID or name of the service
      # @param details [Boolean, nil] Show service context and extra details
      # provided to logs.
      # @param follow [Boolean, nil] Keep connection after returning logs.
      # @param stdout [Boolean, nil] Return logs from `stdout`
      # @param stderr [Boolean, nil] Return logs from `stderr`
      # @param since [Integer, nil] Only return logs since this time, as a UNIX
      # timestamp
      # @param timestamps [Boolean, nil] Add timestamps to every log line
      # @param tail [String, nil] Only return this number of log lines from the
      # end of the logs. Specify as an integer or `all` to output all log lines.
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- no such service
      # @raise [Docker::API::ServerError] 500 -- server error
      # @raise [Docker::API::ServerError] 503 -- node is not part of a swarm
      def service_logs(
        id:,
        details: nil,
        follow: nil,
        stdout: nil,
        stderr: nil,
        since: nil,
        timestamps: nil,
        tail: nil,
        &block
      )
        connection.request(
          :get,
          "/services/#{Path.escape(id)}/logs",
          query: {
            "details" => details,
            "follow" => follow,
            "stdout" => stdout,
            "stderr" => stderr,
            "since" => since,
            "timestamps" => timestamps,
            "tail" => tail,
          },
          expects: [200],
          operation: "service_logs",
          &block
        )
      end

      # Update a service
      #
      # @!method service_update
      # Engine API: POST /services/{id}/update
      #
      # @param id [String] ID or name of service.
      # @param body [Hash] (body parameter 'body' in the API specification)
      # @param version [Integer] The version number of the service object being
      # updated. This is required to avoid conflicting writes. This version
      # number should be the value as currently set o...
      # @param registry_auth_from [String, nil] If the `X-Registry-Auth` header
      # is not specified, this parameter indicates where to find registry
      # authorization credentials. (sent to the daemon as 'registryAuthFrom')
      # @param rollback [String, nil] Set to this parameter to `previous` to
      # cause a server-side rollback to the previous service spec. The supplied
      # spec will be ignored in this case.
      # @param x_registry_auth [String, nil] A base64url-encoded auth
      # configuration for pulling from private registries. (sent to the daemon
      # as 'X-Registry-Auth')
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::BadRequest] 400 -- bad parameter
      # @raise [Docker::API::NotFound] 404 -- no such service
      # @raise [Docker::API::ServerError] 500 -- server error
      # @raise [Docker::API::ServerError] 503 -- node is not part of a swarm
      def service_update(id:, body:, version:, registry_auth_from: nil, rollback: nil, x_registry_auth: nil, &block)
        connection.request(
          :post,
          "/services/#{Path.escape(id)}/update",
          query: { "version" => version, "registryAuthFrom" => registry_auth_from, "rollback" => rollback },
          headers: { "X-Registry-Auth" => x_registry_auth }.compact,
          body: body,
          expects: [200],
          operation: "service_update",
          &block
        )
      end

      # Initialize interactive session
      #
      # Start a new interactive session with a server. Session allows server to
      # call back to the client for advanced capabilities.
      #
      # @!method session
      # Engine API: POST /session
      #
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::ClientError] 101 -- no error, hijacking successful
      # @raise [Docker::API::BadRequest] 400 -- bad parameter
      # @raise [Docker::API::ServerError] 500 -- server error
      def session(&block)
        connection.request(
          :post,
          "/session",
          expects: [200],
          operation: "session",
          &block
        )
      end

      # Initialize a new swarm
      #
      # @!method swarm_init
      # Engine API: POST /swarm/init
      #
      # @param body [Hash] (body parameter 'body' in the API specification)
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::BadRequest] 400 -- bad parameter
      # @raise [Docker::API::ServerError] 500 -- server error
      # @raise [Docker::API::ServerError] 503 -- node is already part of a swarm
      def swarm_init(body:, &block)
        connection.request(
          :post,
          "/swarm/init",
          body: body,
          expects: [200],
          operation: "swarm_init",
          &block
        )
      end

      # Inspect swarm
      #
      # @!method swarm_inspect
      # Engine API: GET /swarm
      #
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- no such swarm
      # @raise [Docker::API::ServerError] 500 -- server error
      # @raise [Docker::API::ServerError] 503 -- node is not part of a swarm
      def swarm_inspect(&block)
        connection.request(
          :get,
          "/swarm",
          expects: [200],
          operation: "swarm_inspect",
          &block
        )
      end

      # Join an existing swarm
      #
      # @!method swarm_join
      # Engine API: POST /swarm/join
      #
      # @param body [Hash] (body parameter 'body' in the API specification)
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::BadRequest] 400 -- bad parameter
      # @raise [Docker::API::ServerError] 500 -- server error
      # @raise [Docker::API::ServerError] 503 -- node is already part of a swarm
      def swarm_join(body:, &block)
        connection.request(
          :post,
          "/swarm/join",
          body: body,
          expects: [200],
          operation: "swarm_join",
          &block
        )
      end

      # Leave a swarm
      #
      # @!method swarm_leave
      # Engine API: POST /swarm/leave
      #
      # @param force [Boolean, nil] Force leave swarm, even if this is the last
      # manager or that it will break the cluster.
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::ServerError] 500 -- server error
      # @raise [Docker::API::ServerError] 503 -- node is not part of a swarm
      def swarm_leave(force: nil, &block)
        connection.request(
          :post,
          "/swarm/leave",
          query: { "force" => force },
          expects: [200],
          operation: "swarm_leave",
          &block
        )
      end

      # Unlock a locked manager
      #
      # @!method swarm_unlock
      # Engine API: POST /swarm/unlock
      #
      # @param body [Hash] (body parameter 'body' in the API specification)
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::ServerError] 500 -- server error
      # @raise [Docker::API::ServerError] 503 -- node is not part of a swarm
      def swarm_unlock(body:, &block)
        connection.request(
          :post,
          "/swarm/unlock",
          body: body,
          expects: [200],
          operation: "swarm_unlock",
          &block
        )
      end

      # Get the unlock key
      #
      # @!method swarm_unlockkey
      # Engine API: GET /swarm/unlockkey
      #
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::ServerError] 500 -- server error
      # @raise [Docker::API::ServerError] 503 -- node is not part of a swarm
      def swarm_unlockkey(&block)
        connection.request(
          :get,
          "/swarm/unlockkey",
          expects: [200],
          operation: "swarm_unlockkey",
          &block
        )
      end

      # Update a swarm
      #
      # @!method swarm_update
      # Engine API: POST /swarm/update
      #
      # @param body [Hash] (body parameter 'body' in the API specification)
      # @param version [Integer] The version number of the swarm object being
      # updated. This is required to avoid conflicting writes.
      # @param rotate_worker_token [Boolean, nil] Rotate the worker join token.
      # (sent to the daemon as 'rotateWorkerToken')
      # @param rotate_manager_token [Boolean, nil] Rotate the manager join
      # token. (sent to the daemon as 'rotateManagerToken')
      # @param rotate_manager_unlock_key [Boolean, nil] Rotate the manager
      # unlock key. (sent to the daemon as 'rotateManagerUnlockKey')
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::BadRequest] 400 -- bad parameter
      # @raise [Docker::API::ServerError] 500 -- server error
      # @raise [Docker::API::ServerError] 503 -- node is not part of a swarm
      def swarm_update(
        body:,
        version:,
        rotate_worker_token: nil,
        rotate_manager_token: nil,
        rotate_manager_unlock_key: nil,
        &block
      )
        connection.request(
          :post,
          "/swarm/update",
          query: {
            "version" => version,
            "rotateWorkerToken" => rotate_worker_token,
            "rotateManagerToken" => rotate_manager_token,
            "rotateManagerUnlockKey" => rotate_manager_unlock_key,
          },
          body: body,
          expects: [200],
          operation: "swarm_update",
          &block
        )
      end

      # Check auth configuration
      #
      # Validate credentials for a registry and, if available, get an identity
      # token for accessing the registry without password.
      #
      # @!method system_auth
      # Engine API: POST /auth
      #
      # @param body [Hash, nil] Authentication to check (body parameter
      # 'authConfig' in the API specification)
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::Unauthorized] 401 -- Auth error
      # @raise [Docker::API::ServerError] 500 -- Server error
      def system_auth(body: nil, &block)
        connection.request(
          :post,
          "/auth",
          body: body,
          expects: [200, 204],
          operation: "system_auth",
          &block
        )
      end

      # Get data usage information
      #
      # @!method system_data_usage
      # Engine API: GET /system/df
      #
      # @param type [Array<String>, nil] Object types, for which to compute and
      # return data.
      # @param verbose [Boolean, nil] Show detailed information on space usage.
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::ServerError] 500 -- server error
      def system_data_usage(type: nil, verbose: nil, &block)
        connection.request(
          :get,
          "/system/df",
          query: { "type" => type, "verbose" => verbose },
          expects: [200],
          operation: "system_data_usage",
          &block
        )
      end

      # Monitor events
      #
      # Stream real-time events from the server.
      #
      # @!method system_events
      # Engine API: GET /events
      #
      # @param since [String, nil] Show events created since this timestamp then
      # stream new events.
      # @param until_ [String, nil] Show events created until this timestamp
      # then stop streaming. (sent to the daemon as 'until')
      # @param filters [String, nil] A JSON encoded value of filters (a
      # `map[string][]string`) to process on the event list. Available filters:
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::BadRequest] 400 -- bad parameter
      # @raise [Docker::API::ServerError] 500 -- server error
      def system_events(since: nil, until_: nil, filters: nil, &block)
        connection.request(
          :get,
          "/events",
          query: { "since" => since, "until" => until_, "filters" => filters },
          expects: [200],
          operation: "system_events",
          &block
        )
      end

      # Get system information
      #
      # @!method system_info
      # Engine API: GET /info
      #
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::ServerError] 500 -- Server error
      def system_info(&block)
        connection.request(
          :get,
          "/info",
          expects: [200],
          operation: "system_info",
          &block
        )
      end

      # Ping
      #
      # This is a dummy endpoint you can use to test if the server is accessible.
      #
      # @!method system_ping
      # Engine API: GET /_ping
      #
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::ServerError] 500 -- server error
      def system_ping(&block)
        connection.request(
          :get,
          "/_ping",
          expects: [200],
          operation: "system_ping",
          &block
        )
      end

      # Ping
      #
      # This is a dummy endpoint you can use to test if the server is accessible.
      #
      # @!method system_ping_head
      # Engine API: HEAD /_ping
      #
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::ServerError] 500 -- server error
      def system_ping_head(&block)
        connection.request(
          :head,
          "/_ping",
          expects: [200],
          operation: "system_ping_head",
          &block
        )
      end

      # Get version
      #
      # Returns the version of Docker that is running and various information
      # about the system that Docker is running on.
      #
      # @!method system_version
      # Engine API: GET /version
      #
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::ServerError] 500 -- server error
      def system_version(&block)
        connection.request(
          :get,
          "/version",
          expects: [200],
          operation: "system_version",
          &block
        )
      end

      # Inspect a task
      #
      # @!method task_inspect
      # Engine API: GET /tasks/{id}
      #
      # @param id [String] ID of the task
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- no such task
      # @raise [Docker::API::ServerError] 500 -- server error
      # @raise [Docker::API::ServerError] 503 -- node is not part of a swarm
      def task_inspect(id:, &block)
        connection.request(
          :get,
          "/tasks/#{Path.escape(id)}",
          expects: [200],
          operation: "task_inspect",
          &block
        )
      end

      # List tasks
      #
      # @!method task_list
      # Engine API: GET /tasks
      #
      # @param filters [String, nil] A JSON encoded value of the filters (a
      # `map[string][]string`) to process on the tasks list.
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::ServerError] 500 -- server error
      # @raise [Docker::API::ServerError] 503 -- node is not part of a swarm
      def task_list(filters: nil, &block)
        connection.request(
          :get,
          "/tasks",
          query: { "filters" => filters },
          expects: [200],
          operation: "task_list",
          &block
        )
      end

      # Get task logs
      #
      # Get `stdout` and `stderr` logs from a task. See also
      # [`/containers/{id}/logs`](#operation/ContainerLogs).
      #
      # @!method task_logs
      # Engine API: GET /tasks/{id}/logs
      #
      # @param id [String] ID of the task
      # @param details [Boolean, nil] Show task context and extra details
      # provided to logs.
      # @param follow [Boolean, nil] Keep connection after returning logs.
      # @param stdout [Boolean, nil] Return logs from `stdout`
      # @param stderr [Boolean, nil] Return logs from `stderr`
      # @param since [Integer, nil] Only return logs since this time, as a UNIX
      # timestamp
      # @param timestamps [Boolean, nil] Add timestamps to every log line
      # @param tail [String, nil] Only return this number of log lines from the
      # end of the logs. Specify as an integer or `all` to output all log lines.
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- no such task
      # @raise [Docker::API::ServerError] 500 -- server error
      # @raise [Docker::API::ServerError] 503 -- node is not part of a swarm
      def task_logs(
        id:,
        details: nil,
        follow: nil,
        stdout: nil,
        stderr: nil,
        since: nil,
        timestamps: nil,
        tail: nil,
        &block
      )
        connection.request(
          :get,
          "/tasks/#{Path.escape(id)}/logs",
          query: {
            "details" => details,
            "follow" => follow,
            "stdout" => stdout,
            "stderr" => stderr,
            "since" => since,
            "timestamps" => timestamps,
            "tail" => tail,
          },
          expects: [200],
          operation: "task_logs",
          &block
        )
      end

      # Create a volume
      #
      # @!method volume_create
      # Engine API: POST /volumes/create
      #
      # @param body [Hash] Volume configuration (body parameter 'volumeConfig'
      # in the API specification)
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::ServerError] 500 -- Server error
      def volume_create(body:, &block)
        connection.request(
          :post,
          "/volumes/create",
          body: body,
          expects: [201],
          operation: "volume_create",
          &block
        )
      end

      # Remove a volume
      #
      # Instruct the driver to remove the volume.
      #
      # @!method volume_delete
      # Engine API: DELETE /volumes/{name}
      #
      # @param name [String] Volume name or ID
      # @param force [Boolean, nil] Force the removal of the volume
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- No such volume or volume driver
      # @raise [Docker::API::Conflict] 409 -- Volume is in use and cannot be
      # removed
      # @raise [Docker::API::ServerError] 500 -- Server error
      def volume_delete(name:, force: nil, &block)
        connection.request(
          :delete,
          "/volumes/#{Path.escape(name)}",
          query: { "force" => force },
          expects: [204],
          operation: "volume_delete",
          &block
        )
      end

      # Inspect a volume
      #
      # @!method volume_inspect
      # Engine API: GET /volumes/{name}
      #
      # @param name [String] Volume name or ID
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::NotFound] 404 -- No such volume
      # @raise [Docker::API::ServerError] 500 -- Server error
      def volume_inspect(name:, &block)
        connection.request(
          :get,
          "/volumes/#{Path.escape(name)}",
          expects: [200],
          operation: "volume_inspect",
          &block
        )
      end

      # List volumes
      #
      # @!method volume_list
      # Engine API: GET /volumes
      #
      # @param filters [String, nil] JSON encoded value of the filters (a
      # `map[string][]string`) to process on the volumes list. Available
      # filters:
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::ServerError] 500 -- Server error
      def volume_list(filters: nil, &block)
        connection.request(
          :get,
          "/volumes",
          query: { "filters" => filters },
          expects: [200],
          operation: "volume_list",
          &block
        )
      end

      # Delete unused volumes
      #
      # @!method volume_prune
      # Engine API: POST /volumes/prune
      #
      # @param filters [String, nil] Filters to process on the prune list,
      # encoded as JSON (a `map[string][]string`).
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::ServerError] 500 -- Server error
      def volume_prune(filters: nil, &block)
        connection.request(
          :post,
          "/volumes/prune",
          query: { "filters" => filters },
          expects: [200],
          operation: "volume_prune",
          &block
        )
      end

      # "Update a volume. Valid only for Swarm cluster volumes"
      #
      # @!method volume_update
      # Engine API: PUT /volumes/{name}
      #
      # @param name [String] The name or ID of the volume
      # @param version [Integer] The version number of the volume being updated.
      # This is required to avoid conflicting writes. Found in the volume's
      # `ClusterVolume` field.
      # @param body [Hash, nil] The spec of the volume to update. Currently,
      # only Availability may change. All other fields must remain unchanged.
      # (body parameter 'body' in the API specification)
      # @yieldparam chunk [String] successive body chunks, when a block is given
      # @return [Docker::API::Response]
      # @raise [Docker::API::BadRequest] 400 -- bad parameter
      # @raise [Docker::API::NotFound] 404 -- no such volume
      # @raise [Docker::API::ServerError] 500 -- server error
      # @raise [Docker::API::ServerError] 503 -- node is not part of a swarm
      def volume_update(name:, version:, body: nil, &block)
        connection.request(
          :put,
          "/volumes/#{Path.escape(name)}",
          query: { "version" => version },
          body: body,
          expects: [200],
          operation: "volume_update",
          &block
        )
      end

    end
  end
end
