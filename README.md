# docker-api-ng

A Ruby client for the modern Docker Engine API.

- **No runtime dependencies.** Everything it needs ships with Ruby.
- **Complete API coverage, by construction.** All 108 Engine API operations are
  generated from Docker's own OpenAPI specification, so nothing is missing and
  keeping up with Docker is a reviewable diff rather than manual archaeology.
- **An ergonomic layer on top.** Collections and resource objects for the things
  you touch every day, with the generated layer underneath whenever you need
  something it has not grown sugar for.
- **Testable without a daemon.** The whole client can be driven by a scripted
  transport, so tests are fast, hermetic and honest.

```ruby
require "docker/api"

client = Docker::API::Client.new

client.images.pull("alpine:3.20")
container = client.containers.create(image: "alpine:3.20", name: "hello", cmd: %w{sleep 60})
container.start

result = container.exec(%w{cat /etc/alpine-release})
result.stdout   #=> "3.20.3\n"
result.exit_code #=> 0

container.remove(force: true)
```

## Installation

```ruby
gem "docker-api-ng"
```

Requires Ruby 3.1 or newer and a daemon speaking Engine API v1.41 or newer
(Docker 20.10+).

## Connecting

With no arguments, a client resolves its daemon exactly as the `docker` CLI
does: `DOCKER_HOST`, then `DOCKER_CERT_PATH` and `DOCKER_TLS_VERIFY` for TLS,
falling back to the platform's default socket.

```ruby
client = Docker::API::Client.new

client = Docker::API::Client.new(url: "unix:///var/run/docker.sock")
client = Docker::API::Client.new(url: "npipe:////./pipe/docker_engine")   # Windows
client = Docker::API::Client.new(
  url: "tcp://build.internal:2376",
  tls: { ca_file: "ca.pem", cert_file: "cert.pem", key_file: "key.pem" }
)
```

A client owns its configuration and its connection, and there is no global
state behind it. Two clients talking to two daemons share nothing:

```ruby
local = Docker::API::Client.new
build = Docker::API::Client.new(url: "tcp://build.internal:2376")
```

See [docs/connecting.md](docs/connecting.md) for version negotiation, timeouts,
logging and TLS in detail.

## Containers

```ruby
client.containers.all(all: true)          # => [Container]
client.containers.get("web")              # => Container, raises NotFound
client.containers.find("web")             # => Container or nil

container = client.containers.create(
  image: "alpine:3.20",
  name: "worker",
  cmd: %w{sleep 3600},
  env: ["LOG_LEVEL=debug"],
  host_config: { "Binds" => ["/data:/data:ro"] }
)

container.start
container.stop(timeout: 10)
container.remove(force: true, volumes: true)
```

Body attributes may be written in snake_case and are translated to the daemon's
spelling. Keys already in Docker's convention pass through untouched, so a
configuration copied out of Docker's documentation works as-is.

### Resources answer the same question the same way

`GET /containers/json` reports `Names: ["/web"]`. `GET /containers/{id}/json`
reports `Name: "/web"`. Resources here normalise that, so code does not have to
know which call produced the object it is holding:

```ruby
listed    = client.containers.all.first    # from a list
inspected = client.containers.get("web")   # from an inspect

listed.name    == inspected.name    # => true
listed.state   == inspected.state   # => true
listed.ports   == inspected.ports   # => true
```

An object built from a list marks itself `partial?`. The first accessor that
needs detail the list did not carry fetches it once, rather than returning nil
and leaving you to guess why. The untouched payload is always available as
`#raw`.

## Running commands

```ruby
result = container.exec(%w{chef-client -z}, env: { "TERM" => "xterm" }) do |stream, chunk|
  logger << chunk if stream == :stdout
end

result.stdout
result.stderr
result.exit_code
result.success?
```

Without a TTY the daemon multiplexes both streams down one connection with an
eight-byte frame header. That is decoded for you, so `:stdout` and `:stderr`
arrive separately instead of interleaved. A non-zero exit is returned rather
than raised — whether a failing command is an error depends on why you ran it.
Use `result.check!` when it is.

## Images

```ruby
client.images.pull("alpine:3.20", platform: "linux/arm64") { |event| puts event["status"] }
client.images.build(context: "./app", tag: "app:dev") { |event| print event["stream"] }
client.images.build(dockerfile: "FROM alpine\nRUN apk add curl\n", tag: "curl:dev")
client.images.ensure("alpine:3.20")   # pull only if absent
```

Registry credentials are resolved per call from `~/.docker/config.json`,
including `credsStore` and `credHelpers`, so pulling from two private
registries in one process needs no setup between calls.

## Networks and volumes

```ruby
network = client.networks.ensure("dokken", ipv6: true)
network.connect(container, aliases: %w{web})
network.disconnect(container)

volume = client.volumes.create("cache", labels: { "team" => "infra" })
volume.remove
```

`ensure` treats losing a creation race as success, because two processes
racing to create the same shared network is ordinary rather than exceptional.

## The daemon itself

```ruby
client.system.info
client.system.version
client.system.ping?      # => true / false, never raises
client.system.podman?    # Podman wearing Docker's API
client.system.rootless?

client.system.events(filters: { "type" => ["container"] }) do |event|
  puts "#{event["Action"]} #{event.dig("Actor", "Attributes", "name")}"
end
```

## Everything else

The generated layer is public API, not an escape hatch. Every one of the 108
Engine API operations is there, documented, typed, and named after the
specification's own `operationId`:

```ruby
client.operations.container_prune(filters: { "until" => ["24h"] })
client.operations.swarm_init(body: { "ListenAddr" => "0.0.0.0:2377" })
client.operations.service_list(filters: { "name" => ["web"] })
client.operations.node_list
client.operations.secret_create(body: { "Name" => "token", "Data" => encoded })
client.operations.plugin_list
```

The ergonomic collections above cover what most code reaches for. Anything they
have not grown sugar for is reachable here with no loss of capability, and the
list of ergonomic wrappers grows over time without ever being a coverage
bottleneck.

## Errors

Everything this gem raises descends from `Docker::API::Error`, and nothing from
beneath the abstraction escapes — no `Errno`, no `OpenSSL`, no `Net::` class
reaches your rescue clause. The original is always kept as `#cause`.

```ruby
begin
  client.containers.get("missing")
rescue Docker::API::NotFound => e
  e.operation  #=> "container_inspect"
  e.status     #=> 404
  e.message    #=> "container_inspect failed (HTTP 404): No such container: missing"
rescue Docker::API::ConnectionError => e
  e.cause      #=> #<Errno::ENOENT ...>
end
```

See [docs/errors.md](docs/errors.md) for the full hierarchy.

## Testing code that uses this gem

`Docker::API::Transport::Fake` scripts a daemon over a real socket pair, so
tests exercise the actual request path with no network and no daemon:

```ruby
fake = Docker::API::Transport::Fake.new([
  "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: 26\r\n\r\n" \
  '{"Id":"abc","Name":"/web"}',
])
client = Docker::API::Client.new(transport: fake, api_version: "1.55")

client.containers.get("web").name  #=> "web"
fake.requests.first                #=> "GET /v1.55/containers/web/json HTTP/1.1\r\n..."
```

The socket is genuine on purpose: `Net::BufferedIO` calls `read_nonblock`,
`write` and `to_io` on whatever it is handed, and a StringIO does not honour
that contract. Faking it produces tests that pass against something the real
code could never drive.

## How it stays current

The API surface is generated from `data/swagger/v1.55.yaml`, a vendored copy of
Docker's own specification:

```console
$ bundle exec rake api:sync[1.56]     # fetch a newer spec and regenerate
$ git diff --stat                     # review what changed
```

A new endpoint appears as a new method. A removed parameter vanishes from the
signature and the type checker names every caller that still passes it.
Generated files are committed, so installing the gem needs no toolchain, and
upgrading the supported API version is a pull request somebody reads.

See [docs/extending.md](docs/extending.md).

## Documentation

| Guide | What it covers |
| --- | --- |
| [Connecting](docs/connecting.md) | URLs, TLS, named pipes, version negotiation, timeouts, logging |
| [Errors](docs/errors.md) | The hierarchy, what each one means, retrying |
| [Running commands](docs/exec.md) | exec, attach, logs, stream multiplexing |
| [Building images](docs/building-images.md) | Build contexts, .dockerignore, build args, registries |
| [Streaming](docs/streaming.md) | The three wire formats and how they are decoded |
| [Extending](docs/extending.md) | The generator, adding ergonomics, upgrading the API version |
| [Migrating from docker-api](docs/migrating-from-docker-api.md) | A call-by-call table |

## Relationship to the docker-api gem

This is not a fork and keeps no compatibility with
[docker-api](https://github.com/upserve/docker-api). It was written because a
few of that gem's design decisions are difficult to work around from outside:
process-global connection and credential state, hand-transcribed parameters
that silently drop what they miss, `Excon` exceptions reaching callers, and no
Windows named pipe support.

Everything here lives under `Docker::API` and nothing is added to `::Docker`,
so both gems can be loaded into one process while a migration is in progress.

## Licence

Apache-2.0. See [LICENSE](LICENSE).
