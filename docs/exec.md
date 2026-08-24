# Running commands in containers

## exec

```ruby
result = container.exec(%w{chef-client -z})

result.stdout     #=> "Starting Chef Infra Client...\n"
result.stderr     #=> ""
result.exit_code  #=> 0
result.success?   #=> true
result.output     #=> stdout and stderr together
```

`exec` creates an exec instance, starts it, reads the stream to completion, and
then asks the daemon for the exit code. All four steps are one call.

### Streaming as it runs

```ruby
container.exec(%w{make test}) do |stream, chunk|
  logger << chunk if stream == :stdout
end
```

The block receives chunks as they arrive, and the returned `ExecResult` still
carries the complete output. Both are available; you do not have to choose.

### Options

```ruby
container.exec(
  %w{bundle exec rake},
  env: { "RAILS_ENV" => "test" },
  user: "app",
  working_dir: "/srv/app",
  tty: false,
  privileged: false
)
```

`tty: true` asks the daemon for a terminal, which means output arrives
unframed. Everything is then reported as `:stdout`, because with a TTY there is
genuinely only one stream.

### Failure is returned, not raised

A non-zero exit is a result, not an exception. Whether a failing command is an
error depends entirely on why it was run — a test runner expects failures, a
provisioning step does not — so the decision stays with the caller:

```ruby
result = container.exec(%w{rspec})
warn "tests failed" unless result.success?

container.exec(%w{apt-get update}).check!   # raises when this one fails
```

`check!` raises a `Docker::API::Error` whose message includes the exit code and
whatever the command said.

## Logs

```ruby
container.logs                                   # everything, as a string
container.logs(tail: 100)
container.logs(since: Time.now.to_i - 3600)
container.logs(timestamps: true)

container.logs(follow: true) do |stream, chunk|
  $stdout << chunk
end
```

Without a block the whole log is returned. With one, chunks are yielded as they
arrive. `follow: true` does not end on its own — break out of the block.

## Attach

`exec` runs a new command. `attach` connects to the container's own process,
and returns the socket so you can write to its stdin:

```ruby
io = container.attach(stdin: true, stdout: true, stderr: true)
io.write("ls /\n")
puts io.readpartial(4096)
io.close
```

## Copying files

```ruby
archive = Docker::API::Tar.pack_dockerfile("unused", files: { "config.yml" => yaml })
container.archive_in(archive.read, path: "/etc/app")

tar_bytes = container.archive_out("/var/log/app.log")
```

Both take and produce tar archives, which is the only format the daemon's copy
endpoints speak.
