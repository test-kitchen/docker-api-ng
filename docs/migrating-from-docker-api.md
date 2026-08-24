# Migrating from the docker-api gem

This gem keeps no compatibility with
[docker-api](https://github.com/upserve/docker-api). Everything lives under
`Docker::API` and nothing is added to `::Docker`, so **both gems can be loaded
into one process** while a migration is in progress. There is no flag day.

## The shape of the change

| docker-api | docker-api-ng |
| --- | --- |
| Class methods plus a connection argument | Everything hangs off a client |
| `Docker.url = host` (process-global) | `Client.new(url: host)` (per client) |
| `Docker.creds = ...` (process-global) | Resolved per call from `~/.docker/config.json` |
| `Docker::Error::DockerError` | `Docker::API::Error` |
| `Excon::Error::Socket` reaches you | `Docker::API::ConnectionError`, cause preserved |
| `.info` — shape depends on the call | Normalised accessors, plus `#raw` |

## Call by call

### The daemon

| docker-api | docker-api-ng |
| --- | --- |
| `Docker.info(conn)` | `client.system.info` |
| `Docker.version(conn)` | `client.system.version` |
| `Docker.ping(conn)` | `client.system.ping?` |
| `Docker.authenticate!(creds)` | `client.system.authenticate(username:, password:)` |
| `Docker.options` / `Docker.url=` | `Docker::API::Client.new(url:, tls:)` |
| `Docker::Connection.new(url, opts)` | `Docker::API::Client.new(url:, tls:)` |

### Containers

| docker-api | docker-api-ng |
| --- | --- |
| `Docker::Container.get(name, {}, conn)` | `client.containers.get(name)` |
| `Docker::Container.all({ all: true }, conn)` | `client.containers.all(all: true)` |
| `Docker::Container.create(args, conn)` | `client.containers.create(**args)` |
| `container.start` | `container.start` |
| `container.stop` | `container.stop(timeout:)` |
| `container.delete(force: true)` | `container.remove(force: true)` |
| `container.json` | `container.raw`, or a named accessor |
| `container.exec(cmd, wait:, "e" => env) { }` | `container.exec(cmd, env: env) { }` |
| `container.info["Names"].include?("/x")` | `container.name == "x"` |

`exec` returns a `Docker::API::ExecResult` with `#stdout`, `#stderr` and
`#exit_code`, rather than a three-element array:

```ruby
# docker-api
out = container.exec(cmd, wait: 60) { |_stream, chunk| logger << chunk }
raise if out[2] != 0

# docker-api-ng
result = container.exec(cmd) { |_stream, chunk| logger << chunk }
raise unless result.success?
```

### Images

| docker-api | docker-api-ng |
| --- | --- |
| `Docker::Image.exist?(name, {}, conn)` | `client.images.exist?(name)` |
| `Docker::Image.get(name, {}, conn)` | `client.images.get(name)` |
| `Docker::Image.create({ "fromImage" => x }, creds, conn)` | `client.images.pull(x)` |
| `Docker::Image.build(dockerfile, opts, conn)` | `client.images.build(dockerfile:, tag:)` |
| `Docker::Image.build_from_dir(dir, opts)` | `client.images.build(context: dir, tag:)` |
| `image.tag("repo" => r, "tag" => t)` | `image.tag("#{r}:#{t}")` |
| `image.remove` | `image.remove` |

### Networks and volumes

| docker-api | docker-api-ng |
| --- | --- |
| `Docker::Network.get(name, {}, conn)` | `client.networks.get(name)` |
| `Docker::Network.create(name, settings)` | `client.networks.create(name, **settings)` |
| get-or-create with a rescue | `client.networks.ensure(name)` |
| `network.info["EnableIPv6"]` | `network.ipv6?` |
| `Docker::Volume.create(name)` | `client.volumes.create(name)` |

### Errors

| docker-api | docker-api-ng |
| --- | --- |
| `Docker::Error::DockerError` | `Docker::API::Error` |
| `Docker::Error::NotFoundError` | `Docker::API::NotFound` |
| `Docker::Error::ConflictError` | `Docker::API::Conflict` |
| `Docker::Error::ServerError` | `Docker::API::ServerError` |
| `Docker::Error::UnexpectedResponseError` | `Docker::API::BadRequest` |
| `Docker::Error::TimeoutError` | `Docker::API::TimeoutError` |
| `Docker::Error::IOError` | `Docker::API::ConnectionError` |
| `Excon::Error::Socket` | `Docker::API::ConnectionError` |

## Workarounds you can now delete

### The dropped `platform` parameter

`Docker::Container.create` forwards only `name` to the query string, so
`platform` never reaches the daemon. The usual workaround is to create the
container and re-fetch it:

```ruby
# docker-api
Docker::Container.create(args, conn)
Docker::Container.get(args["name"], {}, conn)

# docker-api-ng
client.containers.create(name: name, platform: "linux/arm64", **args)
```

### Listing everything to find one container

`Docker::Container.get` is unreliable in docker-api 2.0.0, and the workaround
is to list every container and match by name:

```ruby
# docker-api
found = Docker::Container.all({ all: true }, conn)
  .select { |c| c.info["Names"].include?("/#{name}") }
raise Docker::Error::NotFoundError if found.empty?

# docker-api-ng
client.containers.get(name)
```

### Per-host caching around global state

Because `Docker.url=` is process-global, code that talks to more than one
daemon has to cache results per host to avoid handing the second caller the
first daemon's answers. Two clients need no such care:

```ruby
local = Docker::API::Client.new
build = Docker::API::Client.new(url: "tcp://build:2376")
```

### Rescuing the HTTP library

```ruby
# docker-api
rescue Excon::Error::Socket => e

# docker-api-ng
rescue Docker::API::ConnectionError => e
  e.cause   # the Errno, if you actually want it
```

## Anything not listed here

The complete Engine API is available on `client.operations`, named after the
specification's own operation ids:

```ruby
client.operations.container_prune(filters: { "until" => ["24h"] })
client.operations.image_history(name: "alpine:3.20")
```
