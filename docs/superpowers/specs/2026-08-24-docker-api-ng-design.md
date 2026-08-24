# docker-api-ng Design

**Date:** 2026-08-24
**Status:** Approved, ready for implementation planning

## Purpose

A Ruby client for the modern Docker Engine API, licensed Apache-2.0 and
published publicly.

Two goals, in priority order:

1. Give kitchen-dokken a dependency it can trust, replacing `docker-api`.
2. Cover the complete modern Engine API, and keep covering it as Docker
   changes.

Three qualities the design optimises for throughout: ease of maintenance as
the upstream API moves, testability, and a documented API that is pleasant to
use.

`docker-api` is the reference for what problems exist, not for how to solve
them. No backwards compatibility with it is required or attempted.

## Context

### The daemon

The development daemon runs Docker 29.7.2, Engine API v1.55. Docker publishes
a machine-readable Swagger 2.0 definition of the API:

- Live: `https://raw.githubusercontent.com/moby/moby/master/api/swagger.yaml`
- Frozen per version: `https://docs.docker.com/reference/api/engine/version/v1.NN.yaml`

The master document is 472 KB and defines 98 paths. Its `operationId` values
follow a `NounVerb` convention (`ContainerCreate`, `ImageBuild`), which maps
deterministically onto Ruby method names.

### What kitchen-dokken actually uses

The complete `docker-api` surface consumed by kitchen-dokken today, as a
migration target and as the acceptance criteria for milestone M3:

| Area | Calls |
| --- | --- |
| Top level | `Docker.info`, `Docker.version`, `Docker.options`, `Docker.url=`, `Docker.authenticate!`, `Docker.creds` |
| Connection | `Docker::Connection.new(url, opts)` |
| Container | `.get`, `.all`, `.create`, `#start`, `#stop`, `#delete`, `#json`, `#exec` |
| Image | `.exist?`, `.get`, `.create`, `.build`, `.build_from_dir`, `#tag`, `#remove` |
| Network | `.get`, `.create`, `#info` |
| Errors | `DockerError`, `NotFoundError`, `ConflictError`, `ServerError`, `UnexpectedResponseError`, `TimeoutError`, `IOError` |
| Leaked | `Excon::Error::Socket` |

### Known defects being designed out

These are documented in kitchen-dokken's own source comments. Each becomes a
named regression test in this gem.

1. **`Docker::Container.create` drops query parameters.** It forwards only
   `name`, so `platform` is silently discarded. kitchen-dokken works around
   this by creating the container and re-fetching it.
2. **`Docker::Container.get` is unreliable in docker-api 2.0.0.** kitchen-dokken
   substitutes `Container.all` plus a client-side name match.
3. **Process-global mutable state.** `Docker.url=` and `Docker.creds` are
   global. kitchen-dokken caches `docker_info` per host specifically because a
   second caller would otherwise be handed the first caller's daemon.
4. **The HTTP library leaks.** `Excon::Error::Socket` reaches consumer `rescue`
   clauses, coupling callers to an implementation detail.
5. **No Windows named pipe support.** kitchen-dokken carries a standing TODO
   for `//./pipe/docker_engine`.

## Decisions

| Decision | Choice |
| --- | --- |
| Coverage strategy | Generate from the vendored Swagger spec; commit the output |
| HTTP layer | Ruby stdlib only: `Net::HTTP` over a pluggable socket |
| Public API shape | Client-rooted collections returning resource objects |
| Namespace | `Docker::API`, required as `docker/api` |
| kitchen-dokken migration | Designed for now, executed as a separate project |
| Ruby floor | `>= 3.1`, matching kitchen-dokken |
| Vendored spec | v1.55, with negotiation for older daemons |
| Runtime dependencies | None |

## Architecture

Four layers with a single dependency direction. Each is testable in isolation
against a double of the layer beneath it.

```
Docker::API::Client            HAND-WRITTEN, ergonomic
  client.containers.create(...)  -> Container
  client.images.pull(...)        client.system.info
        |
        v
Docker::API::Operations        GENERATED from swagger.yaml
  one method per operationId, 98 of them
  knows verb, path template, every parameter, success and error codes
  contains no business logic
        |
        v
Docker::API::Connection        HAND-WRITTEN
  version prefix, JSON, errors, retries, logging,
  stream decoding, hijack, registry auth headers
        |
        v
Docker::API::Transport::{Unix,Tcp,Tls,NamedPipe,Fake}
  socket creation, and nothing else
```

### Transport

A transport's entire job is to produce a connected `IO`. That narrowness is
what makes the layer above it testable: `Transport::Fake` is a scripted
in-memory socket, so connection behaviour is tested at byte level with no
network, no `webmock`, and no daemon.

- `Transport::Unix` — `UNIXSocket`, for `unix:///var/run/docker.sock`
- `Transport::Tcp` — `TCPSocket`, for `tcp://host:2375`
- `Transport::Tls` — `OpenSSL::SSL::SSLSocket` with CA, client cert and key
- `Transport::NamedPipe` — Windows `//./pipe/docker_engine`
- `Transport::Fake` — tests

`Net::HTTP#connect` is overridable, so the connection hands `Net::HTTP` a
socket the transport made. That yields chunked decoding, keep-alive and header
parsing for free while retaining raw-socket access, and it is what makes named
pipe support possible without a dependency.

### Connection

Owns everything between "a socket exists" and "a Ruby value comes back":

- prefixing the negotiated API version onto request paths
- JSON encoding and decoding
- mapping HTTP status codes onto the error hierarchy
- structured logging of request and response metadata
- registry authentication headers
- stream decoding
- hijack

Configuration is supplied at construction and frozen. There is no
process-global state anywhere in the gem, and no setter that mutates a live
connection.

### Version negotiation

Docker versions by URL prefix (`/v1.55/containers/json`). On first use the
client requests `/_ping`, reads the `Api-Version` response header, and
negotiates `min(gem_maximum, daemon_version)`.

`api_version:` accepts:

- `:negotiate` — the default, described above
- a pinned string such as `"1.44"`
- `:none` — send unprefixed paths

The minimum supported Engine API version is **v1.41** (Docker 20.10, the oldest
release still plausibly in service). A daemon below it raises
`Docker::API::VersionUnsupported`, naming both versions, at connection time
rather than as a confusing 404 later.

### Errors

Rooted at `Docker::API::Error`. Nothing beneath it escapes: no `Net::` class,
no `Errno`, no `OpenSSL` exception reaches a consumer's `rescue`. Wrapped
exceptions are retained as `#cause`.

```
Docker::API::Error
  ConnectionError      socket refused, reset, DNS failure
  TimeoutError
  ClientError
    BadRequest         400
    Unauthorized       401
    Forbidden          403
    NotFound           404
    NotModified        304
    Conflict           409
  ServerError          5xx
  VersionUnsupported
  StreamError
```

`NotModified` is grouped with the client errors rather than treated as a
redirect because that is the semantics Docker gives it: starting an already
running container returns 304.

Every error carries the operation name, the HTTP status, and the daemon's own
`message` field, so a failure reports what was attempted and what the daemon
said about it.

### Registry authentication

Credentials resolve per call and travel as an `X-Registry-Auth` header on the
request that needs them. Resolution reads `~/.docker/config.json`, including
`credsStore` and `credHelpers` binaries. No global credential store exists.

### Streaming

One `Docker::API::Stream` abstraction covers the three wire formats Docker
uses:

1. **Raw** — TTY-enabled output, an undifferentiated byte stream.
2. **Multiplexed** — the 8-byte frame header format tagging stdout and stderr
   separately. Correct demultiplexing here is what `exec` callbacks depend on.
3. **JSON lines** — progress events from pull, push, build and `/events`.

Consumers pass a block receiving `(stream_name, chunk)`, or take an
`Enumerator` for lazy iteration.

### Hijack

Interactive `exec` and `attach` with stdin require taking over the socket
after a `101 Upgrade`. This path deliberately bypasses `Net::HTTP`: the
connection writes the request line and headers to the raw socket, reads the
status line and headers itself, and returns a bidirectional `IO`. Persuading
`Net::HTTP` to relinquish a buffered socket is the problem that produced
`docker-api`'s custom Excon middleware; avoiding it is simpler and easier to
reason about.

## Code generation

### What is generated

From `data/swagger/v1.55.yaml`:

- `lib/docker/api/operations.rb` — one method per `operationId`
- `lib/docker/api/models.rb` — parameter and response structs
- `sig/docker/api/operations.rbs`, `sig/docker/api/models.rbs`
- `spec/generated/operations_conformance_spec.rb`

Generated output is **plain, readable, committed Ruby**. No runtime
metaprogramming and no `define_method`: the code can be grepped, stepped
through in a debugger, and documented by YARD. Doc comments are lifted from
the spec's own parameter descriptions.

Because output is committed, consumers install an ordinary gem and need no
generator toolchain.

### Shape of a generated method

```ruby
# GENERATED -- do not edit. Source: swagger v1.55, operationId ContainerCreate
#
# @param name [String, nil] Assign the specified name to the container.
# @param platform [String, nil] Platform in the format os[/arch[/variant]]
# @raise [Docker::API::Conflict] 409 -- name already in use
def container_create(body:, name: nil, platform: nil)
  connection.request(
    :post, "/containers/create",
    query: { name: name, platform: platform }.compact,
    body: body, expects: [201]
  )
end
```

Query parameters are read from the spec rather than transcribed by hand, which
is the structural fix for defect 1.

### Conformance tests

The generator emits, for every operation, a test asserting HTTP verb, path
template and parameter set against the spec. A generator regression fails
loudly in CI instead of shipping a silently wrong URL.

### Keeping current

`rake api:sync[1.56]` fetches the named spec version, regenerates all outputs,
and leaves a reviewable git diff. A new endpoint appears as a new method; a
removed parameter vanishes and the Steep type check identifies every caller.
Upgrading the supported API version is a pull request someone reads.

## Public API

### Construction

```ruby
client = Docker::API::Client.new                     # from environment, like the CLI
client = Docker::API::Client.new(url: "unix:///var/run/docker.sock")
client = Docker::API::Client.new(url: "tcp://build:2376", tls: {
  ca_file: "...", cert_file: "...", key_file: "..."
})
```

Environment resolution follows the Docker CLI: `DOCKER_HOST`, `DOCKER_CERT_PATH`,
`DOCKER_TLS_VERIFY`, falling back to the platform default socket.

Two clients pointed at two daemons never interfere, because no state is shared
between them. This is the fix for defect 3.

### Collections and resources

```ruby
client.containers.all(all: true)      # -> [Container]
client.containers.get("dokken-abc")   # -> Container, raises NotFound
client.containers.find("dokken-abc")  # -> Container or nil
c = client.containers.create(image: "alpine", name: "x", platform: "linux/arm64")

c.start
c.exec(["chef-client", "-z"], env: { "TERM" => "xterm" }) { |stream, chunk| log << chunk }
#   -> Docker::API::ExecResult(stdout:, stderr:, exit_code:)
c.logs(follow: true) { |stream, chunk| ... }
c.stop(timeout: 10)
c.remove(force: true, volumes: true)

client.images.pull("alpine:3.20", platform: "linux/arm64")
client.images.build(context: dir, tag: "work:latest", platform: "linux/arm64")
client.networks.get("dokken")
client.volumes.create(name: "dokken-data")
client.system.info
client.system.version
client.system.events { |event| ... }
```

Namespaces: `containers`, `images`, `networks`, `volumes`, `system`, `exec`,
`swarm`, `services`, `nodes`, `tasks`, `secrets`, `configs`, `plugins`,
`distribution`.

### Resource semantics

`GET /containers/json` and `GET /containers/{id}/json` return differently
shaped payloads for the same object: the list form gives `Names: ["/foo"]`,
the inspect form gives `Name: "/foo"`. `docker-api` exposes whichever the
caller happened to fetch, which is the source of kitchen-dokken's mixed
`info["Names"]` and `[:NetworkSettings][:Ports]` access.

Here:

- Normalised accessors (`#name`, `#state`, `#ports`, `#labels`) return the
  same value regardless of which call produced the object.
- A resource built from a list response is `#partial?`. An accessor requiring
  inspect-only data performs exactly one lazy `#reload`.
- `#raw` always returns the untouched daemon payload.
- `#reload` is available explicitly.

### Escape hatch as first-class API

The generated layer is public:

```ruby
client.operations.container_prune(filters: { "until" => ["24h"] })
```

Complete API coverage therefore exists from the first release. The ergonomic
layer is sugar that grows over time and is never a coverage bottleneck.

## Testing

| Tier | Double | Speed | Gate |
| --- | --- | --- | --- |
| Connection and transport | `Transport::Fake`, byte level | instant | always |
| Operations conformance | generated from the spec | instant | always |
| Ergonomic layer | fake `Operations` | instant | always |
| Integration | a real daemon | slow | opt-in, plus a CI job |

The default suite performs no network access. There is no `webmock` and no
`VCR`. `bin/record` captures real daemon exchanges as fixtures that
`Transport::Fake` replays, so an integration finding becomes a unit test.

Framework is minitest with mocha, matching kitchen-dokken, including
`Mocha.configure { |c| c.stubbing_non_existent_method = :prevent }` so a
typo'd stub fails rather than producing a green test over a broken call.

## Tooling

- **Linting** — Cookstyle's chefstyle, matching kitchen-dokken's `.rubocop.yml`
- **Types** — RBS for generated and hand-written code, Steep checked in CI
- **Docs** — YARD with markdown, plus a doc coverage gate failing CI on
  undocumented public API, published to GitHub Pages on release
- **Release** — release-please with `release-type: ruby`, conventional commits
- **Dependencies** — Dependabot
- **CI** — Ruby matrix 3.1 through 4.0, chefstyle, unit suite, integration job
  against a real daemon

## Repository layout

```
lib/docker/api.rb                  entry point
lib/docker/api/client.rb           hand-written ergonomics
lib/docker/api/{containers,images,networks,volumes,system,...}.rb
lib/docker/api/resources/{container,image,network,volume}.rb
lib/docker/api/connection.rb
lib/docker/api/errors.rb
lib/docker/api/stream.rb
lib/docker/api/config.rb
lib/docker/api/auth.rb
lib/docker/api/transport/{unix,tcp,tls,named_pipe,fake}.rb
lib/docker/api/operations.rb       GENERATED
lib/docker/api/models.rb           GENERATED
lib/docker/api/version.rb
sig/                               RBS, generated and hand-written
data/swagger/v1.55.yaml            vendored spec
tasks/codegen.rake                 rake api:sync[VERSION]
spec/                              minitest suites
docs/                              guides
```

`Docker::API` reopens `::Docker` additively and defines no method on it, so
this gem and `docker-api` can be loaded into the same process during
kitchen-dokken's migration.

## Milestones

- **M0** — Skeleton: Apache-2.0 licence, gemspec, CI, release-please
- **M1** — Transport, connection, errors, streaming, tested against
  `Transport::Fake`
- **M2** — Generator, all 98 operations, conformance tests, RBS
- **M3** — Ergonomic layer covering kitchen-dokken's surface: system,
  containers, images, networks, volumes, exec, build, authenticated pull
- **M4** — Remaining ergonomic namespaces: swarm, services, nodes, tasks,
  secrets, configs, plugins, distribution
- **M5** — Documentation, doc coverage gate, Steep in CI, 0.1.0 release

M3 is complete when every `docker-api` call kitchen-dokken makes today has a
documented, tested equivalent, and each of the five known defects has a named
regression test.

## Out of scope

- Backwards compatibility with `docker-api`, including any compatibility shim
- The kitchen-dokken migration itself, which is a separate project against a
  released 0.1.0
- Docker Compose, BuildKit's gRPC protocol, and the Docker CLI's own
  configuration semantics beyond credential resolution
- Asynchronous or fiber-scheduler-aware IO in the first release. The transport
  boundary leaves room for it later without a redesign.
