# Connecting

## Resolution order

`Docker::API::Client.new` with no arguments resolves its daemon the way the
`docker` CLI does:

1. `DOCKER_HOST`, or `DOCKER_URL`
2. `unix:///var/run/docker.sock` on Linux and macOS
3. `npipe:////./pipe/docker_engine` on Windows

TLS material comes from `DOCKER_CERT_PATH`, which is expected to contain
`ca.pem`, `cert.pem` and `key.pem`. `DOCKER_TLS_VERIFY` is a presence flag
rather than a boolean: the CLI treats an exported-but-empty value as off, and
so does this gem.

Explicit arguments always win over the environment.

## URL forms

| Form | Transport |
| --- | --- |
| `unix:///var/run/docker.sock` | `Transport::Unix` |
| `/var/run/docker.sock` | `Transport::Unix` — a bare path is a socket |
| `tcp://host:2375` | `Transport::Tcp` |
| `tcp://host:2376` with `tls:` | `Transport::Tls` |
| `https://host:2376` | `Transport::Tls` |
| `npipe:////./pipe/docker_engine` | `Transport::NamedPipe` |
| `tcp://` | `Transport::Tcp` at localhost:2375 |

## Version negotiation

Docker versions its API by URL prefix: `/v1.55/containers/json`. On first use a
client pings `/_ping`, reads the `Api-Version` header, and settles on
`min(what this gem vendors, what the daemon speaks)`.

```ruby
client = Docker::API::Client.new                          # negotiate (default)
client = Docker::API::Client.new(api_version: "1.44")     # pin; no ping is sent
client = Docker::API::Client.new(api_version: :none)      # send unprefixed paths
```

Negotiation happens once per client, not once per request. A daemon older than
`Docker::API::MIN_API_VERSION` raises `VersionUnsupported` naming both
versions, at connection time rather than as a confusing 404 later.

Pinning is worth doing in CI, where an unexpected daemon upgrade changing
behaviour underneath a test suite is more disruptive than a version mismatch
you can see in the diff.

## Timeouts

```ruby
client = Docker::API::Client.new(read_timeout: 120, open_timeout: 5)
```

`read_timeout` is the wait for response data, not a deadline for the whole
request. Long-running streams — `logs(follow: true)`, `system.events`, a slow
build — are not subject to a total limit, only to a gap between chunks.

## Logging

```ruby
require "logger"
client = Docker::API::Client.new(logger: Logger.new($stdout))
```

One debug line per request, naming the operation, the verb and the resolved
path. Request bodies are not logged: they routinely carry registry credentials
and environment variables.

## TLS

```ruby
client = Docker::API::Client.new(
  url: "tcp://build.internal:2376",
  tls: {
    ca_file: "/certs/ca.pem",
    cert_file: "/certs/cert.pem",
    key_file: "/certs/key.pem",
    verify: true,
  }
)
```

The handshake happens in the transport rather than in `Net::HTTP`, so the layer
above receives an already-encrypted socket and there is one code path for every
transport. TLS 1.2 is the minimum. `verify: false` exists for self-signed
development daemons; it is not a default.

## Windows named pipes

```ruby
client = Docker::API::Client.new(url: "npipe:////./pipe/docker_engine")
```

Both the forward-slash form that appears in `DOCKER_HOST` and the backslash
form Windows itself uses are accepted.
