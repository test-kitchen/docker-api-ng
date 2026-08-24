# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Docker
  module API
    # A container on the daemon.
    #
    # @example Run a command and read its output
    #   container = client.containers.get("web")
    #   result = container.exec(["cat", "/etc/hostname"])
    #   result.stdout #=> "3f2a9c1b0e4d\n"
    #
    # @example Follow logs
    #   container.logs(follow: true) { |stream, chunk| $stdout << chunk }
    class Container < Resource
      # @return [String, nil] the container's name, without the leading slash
      #   the daemon puts on it. Answers identically whether this object came
      #   from a list or an inspect.
      def name
        # "Name" comes from an inspect, "Names" from a list. Both are tried
        # against the payload in hand before any request is made.
        value = detail("Name", "Names")
        value = Array(value).first if value.is_a?(Array)
        value&.sub(%r{\A/}, "")
      end

      # @return [String, nil] "running", "exited", "created", and so on
      def state
        value = detail("State")
        value.is_a?(Hash) ? value["Status"] : value
      end

      # @return [Boolean] whether the container is running right now
      def running?
        state == "running"
      end

      # @return [String, nil] the image the container was created from, by the
      #   name it was requested under rather than by digest
      def image
        # An inspect puts the friendly name in Config.Image and a digest in
        # Image; a list puts the friendly name in Image. Preferring
        # Config.Image gets the readable answer from both without a round trip.
        detail("Config.Image", "Image")
      end

      # @return [Hash] the container's labels
      def labels
        detail("Config.Labels", "Labels") || {}
      end

      # Published ports, in one shape regardless of where the payload came
      # from. A list response reports an array; an inspect response reports a
      # map keyed by port. Both become the same array of hashes here.
      #
      # @return [Array<Hash>] with :port, :protocol, :host_ip and :host_port
      def ports
        listed = raw["Ports"]
        return normalize_listed_ports(listed) if listed.is_a?(Array)

        normalize_inspected_ports(detail("NetworkSettings.Ports") || {})
      end

      # @return [Hash{String => Hash}] networks this container is attached to
      def networks
        detail("NetworkSettings.Networks") || {}
      end

      # @return [String, nil] the container's address on its primary network
      def ip_address
        networks.each_value { |net| return net["IPAddress"] unless net["IPAddress"].to_s.empty? }
        detail("NetworkSettings.IPAddress")
      end

      # @return [Boolean] whether the container was created with a TTY, which
      #   decides whether its output stream is multiplexed
      def tty?
        detail("Config.Tty") == true
      end

      # Re-read this container from the daemon.
      #
      # @return [self]
      def reload
        replace_raw(operations.container_inspect(id: id || name).json)
      end

      # @param detach_keys [String, nil] the key sequence that detaches
      # @return [self]
      def start(detach_keys: nil)
        idempotently { operations.container_start(id: id, detach_keys: detach_keys) }
      end

      # @param timeout [Integer, nil] seconds to wait before killing
      # @param signal [String, nil] the signal to send first
      # @return [self]
      def stop(timeout: nil, signal: nil)
        idempotently { operations.container_stop(id: id, t: timeout, signal: signal) }
      end

      # @param timeout [Integer, nil] seconds to wait before killing
      # @param signal [String, nil] the signal to send first
      # @return [self]
      def restart(timeout: nil, signal: nil)
        idempotently { operations.container_restart(id: id, t: timeout, signal: signal) }
      end

      # @param signal [String, nil] the signal to send, SIGKILL by default
      # @return [self]
      def kill(signal: nil)
        operations.container_kill(id: id, signal: signal)
        mark_stale
      end

      # @return [self]
      def pause
        operations.container_pause(id: id)
        mark_stale
      end

      # @return [self]
      def unpause
        operations.container_unpause(id: id)
        mark_stale
      end

      # @param name [String] the new name
      # @return [self]
      def rename(name)
        operations.container_rename(id: id, name: name)
        reload
      end

      # @param force [Boolean] remove even if running
      # @param volumes [Boolean] remove anonymous volumes too
      # @param link [Boolean] remove the specified link
      # @return [void]
      def remove(force: false, volumes: false, link: false)
        operations.container_delete(id: id, force: force, v: volumes, link: link)
        nil
      end

      # Block until the container stops.
      #
      # @param condition [String, nil] "not-running", "next-exit" or "removed"
      # @return [Integer] the container's exit code
      def wait(condition: nil)
        operations.container_wait(id: id, condition: condition).json!["StatusCode"]
      end

      # @param ps_args [String, nil] arguments passed to ps inside the container
      # @return [Hash] with "Titles" and "Processes"
      def top(ps_args: nil)
        operations.container_top(id: id, ps_args: ps_args).json
      end

      # @return [Hash] a single resource-usage sample
      def stats
        operations.container_stats(id: id, stream: false, one_shot: true).json
      end

      # Read the container's output.
      #
      # Without a block the whole log is returned as a string. With a block,
      # chunks are yielded as they arrive, demultiplexed into named streams
      # unless the container has a TTY, in which case the daemon sends one
      # undifferentiated stream and every chunk is reported as :stdout.
      #
      # @param follow [Boolean] keep streaming as new output appears
      # @param stdout [Boolean] include stdout
      # @param stderr [Boolean] include stderr
      # @param tail [String, Integer, nil] how many trailing lines to start with
      # @param since [Integer, nil] a UNIX timestamp to start from
      # @param timestamps [Boolean] prefix every line with its timestamp
      # @yieldparam stream [Symbol] :stdout or :stderr
      # @yieldparam chunk [String]
      # @return [String, self] the log, or self when a block was given
      def logs(follow: false, stdout: true, stderr: true, tail: nil,
        since: nil, timestamps: false, &block)
        # Defaulted rather than fixed keys: Demultiplexer maps a frame id it
        # does not recognise to :unknown, and a fixed two-key hash turned that
        # into `undefined method '<<' for nil` -- one corrupt frame crashing a
        # log read, with a bare NoMethodError rather than a Docker::API::Error.
        collected = Hash.new { |streams, name| streams[name] = +"" }
        sink = block || ->(stream, chunk) { collected[stream] << chunk }
        decoder = tty? ? Stream::Raw.new { |chunk| sink.call(:stdout, chunk) } : Stream::Demultiplexer.new(&sink)

        operations.container_logs(
          id: id, follow: follow, stdout: stdout, stderr: stderr,
          tail: tail&.to_s, since: since, timestamps: timestamps
        ) { |chunk| decoder << chunk }

        block ? self : collected[:stdout] + collected[:stderr]
      end

      # Run a command inside the container and wait for it to finish.
      #
      # @param command [Array<String>, String] the command and its arguments
      # @param env [Hash] environment variables for the command
      # @param user [String, nil] the user to run as
      # @param working_dir [String, nil] the directory to run in
      # @param tty [Boolean] allocate a TTY, which un-multiplexes the output
      # @param privileged [Boolean] run privileged
      # @yieldparam stream [Symbol] :stdout or :stderr
      # @yieldparam chunk [String]
      # @return [Docker::API::ExecResult]
      #
      # @example
      #   result = container.exec(%w{chef-client -z}) { |_stream, chunk| logger << chunk }
      #   raise "converge failed" unless result.success?
      def exec(command, env: {}, user: nil, working_dir: nil, tty: false,
        privileged: false, &block)
        exec_id = create_exec(command, env, user, working_dir, tty, privileged)
        stdout = +""
        stderr = +""

        sink = lambda do |stream, chunk|
          (stream == :stderr ? stderr : stdout) << chunk
          block&.call(stream, chunk)
        end
        decoder = tty ? Stream::Raw.new { |chunk| sink.call(:stdout, chunk) } : Stream::Demultiplexer.new(&sink)

        operations.exec_start(
          id: exec_id, body: { "Detach" => false, "Tty" => tty }
        ) { |chunk| decoder << chunk }

        ExecResult.new(
          stdout: stdout, stderr: stderr,
          # Not .to_i. The daemon reports "ExitCode": null while an exec is
          # still being reaped, and nil.to_i is 0 -- so a command whose result
          # was not yet known reported success, and #success? agreed. nil
          # travels through instead, and #success? is false for it.
          exit_code: operations.exec_inspect(id: exec_id).json!["ExitCode"]
        )
      end

      # Attach to the container's streams, taking over the socket.
      #
      # @param stdin [Boolean] attach the input stream
      # @param stdout [Boolean] attach standard output
      # @param stderr [Boolean] attach standard error
      # @param logs [Boolean] replay existing output first
      # @return [IO] the bidirectional stream
      def attach(stdin: false, stdout: true, stderr: true, logs: false)
        client.connection.hijack(
          :post, "/containers/#{Path.escape(id)}/attach",
          query: { "stream" => true, "stdin" => stdin, "stdout" => stdout,
                   "stderr" => stderr, "logs" => logs },
          operation: "container_attach"
        )
      end

      # Copy a tar archive into the container.
      #
      # @param archive [String, IO] tar bytes, or an IO that yields them
      # @param path [String] the destination directory inside the container
      # @param overwrite_non_directory [Boolean] allow replacing a file with a
      #   directory, or the reverse
      # @param copy_uid_gid [Boolean] keep the archive's ownership
      # @return [self]
      def archive_in(archive, path:, overwrite_non_directory: true, copy_uid_gid: false)
        operations.put_container_archive(
          id: id, path: path,
          # The content type is not a parameter this endpoint declares, so it
          # is not a keyword the generated layer accepts; the connection
          # labels raw bodies as archives, which is what this one is.
          body: archive.respond_to?(:read) ? archive.read : archive,
          no_overwrite_dir_non_dir: !overwrite_non_directory,
          copy_uidgid: copy_uid_gid
        )
        self
      end

      # Read a path out of the container as a tar archive.
      #
      # @param path [String] the path inside the container
      # @yieldparam chunk [String] tar bytes, when a block is given
      # @return [String, self] the archive, or self when streamed
      def archive_out(path, &block)
        return operations.container_archive(id: id, path: path).body unless block

        operations.container_archive(id: id, path: path, &block)
        self
      end

      # Turn the container's filesystem into an image.
      #
      # @param repo [String, nil] the repository to name it
      # @param tag [String, nil] the tag to give it
      # @param comment [String, nil] a commit message
      # @param author [String, nil] who made it
      # @param pause [Boolean] pause the container while committing
      # @return [Docker::API::Image]
      def commit(repo: nil, tag: nil, comment: nil, author: nil, pause: true)
        response = operations.image_commit(
          container: id, repo: repo, tag: tag, comment: comment,
          author: author, pause: pause
        )
        client.images.get(response.json!["Id"])
      end

      private

      # Run a lifecycle change that Docker treats as idempotent.
      #
      # The daemon answers 304 for "already started" and "already stopped", and
      # the generated layer faithfully raises NotModified for it -- correct
      # there, where fidelity to the specification is the point. It is the
      # wrong default here: converge loops, retry-until-healthy blocks and test
      # fixtures all call start on a container that may already be running, and
      # asking for a state the container is already in is not a failure.
      #
      # Marked stale either way. Rescuing without it left a caller who did
      # handle the exception holding a payload the daemon had already moved on
      # from.
      #
      # @return [self]
      def idempotently
        yield
        mark_stale
      rescue NotModified
        mark_stale
      end

      # @return [String] the id of the created exec instance
      def create_exec(command, env, user, working_dir, tty, privileged)
        body = {
          "AttachStdout" => true,
          "AttachStderr" => true,
          "Tty" => tty,
          "Cmd" => Array(command),
          "Privileged" => privileged,
        }
        body["Env"] = env.map { |key, value| "#{key}=#{value}" } unless env.nil? || env.empty?
        body["User"] = user if user
        body["WorkingDir"] = working_dir if working_dir

        operations.container_exec(id: id, body: body).json!["Id"]
      end

      # @param listed [Array<Hash>]
      # @return [Array<Hash>]
      def normalize_listed_ports(listed)
        listed.map do |entry|
          {
            port: entry["PrivatePort"],
            protocol: entry["Type"],
            host_ip: entry["IP"],
            host_port: entry["PublicPort"],
          }
        end
      end

      # @param inspected [Hash]
      # @return [Array<Hash>]
      def normalize_inspected_ports(inspected)
        inspected.flat_map do |spec, bindings|
          port, _, protocol = spec.partition("/")
          Array(bindings).map do |binding|
            {
              port: port.to_i,
              protocol: protocol,
              host_ip: binding && binding["HostIp"],
              host_port: binding && binding["HostPort"]&.to_i,
            }
          end.then { |mapped| mapped.empty? ? [{ port: port.to_i, protocol: protocol, host_ip: nil, host_port: nil }] : mapped }
        end
      end
    end
  end
end
