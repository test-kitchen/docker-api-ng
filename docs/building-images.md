# Building images

## From a directory

```ruby
image = client.images.build(context: "./app", tag: "app:dev") do |event|
  print event["stream"] if event["stream"]
end
```

The directory is packed into a tar archive with `Gem::Package::TarWriter`,
which ships with Ruby — no dependency, no shelling out to `tar`, and identical
behaviour on Windows where there may be no `tar` to shell out to.

`.dockerignore` is honoured, including `!` negations, where the last matching
rule wins.

## From a Dockerfile in memory

For a short generated build with no accompanying files, writing a temporary
directory first is ceremony for its own sake:

```ruby
client.images.build(
  dockerfile: <<~DOCKERFILE,
    FROM alpine:3.20
    RUN apk add --no-cache curl
  DOCKERFILE
  tag: "curl:dev"
)
```

## Options

```ruby
client.images.build(
  context: "./app",
  dockerfile: "Dockerfile.ci",           # a path within the context
  tag: "app:ci",
  platform: "linux/arm64",
  buildargs: { "VERSION" => "2026.08" },
  labels: { "team" => "infra" },
  target: "runtime",                     # stop at a multi-stage stage
  nocache: true,
  pull: true,
  rm: true
)
```

## Build failures

The daemon reports a failed build inside a `200` response, as an `error` key in
the JSON-lines stream. Anything that only checks the HTTP status concludes the
build succeeded and then fails confusingly later.

`build` reads the stream and raises:

```ruby
begin
  client.images.build(context: ".", tag: "app:dev")
rescue Docker::API::Error => e
  e.message  #=> "image build failed: The command '/bin/sh -c apk add nope' returned a non-zero code: 1"
end
```

## Pulling

```ruby
client.images.pull("alpine:3.20")
client.images.pull("ghcr.io/team/app:1.0", platform: "linux/arm64")
client.images.ensure("alpine:3.20")     # pull only if it is not already here
```

Credentials are resolved for the registry in the reference, from
`~/.docker/config.json`, including `credsStore` and `credHelpers`. Every
failure in that lookup is soft: a missing config file, an unreadable one, or an
uninstalled helper all mean "no credentials", because anonymous pulls of public
images must keep working on a machine that has never run `docker login`.

Pass `auth:` to override:

```ruby
credentials = Docker::API::Auth.encode(
  username: "token", password: ENV.fetch("REGISTRY_TOKEN"), serveraddress: "ghcr.io"
)
client.images.pull("ghcr.io/team/app:1.0", auth: credentials)
```

## A note on `platform`

The Engine API asks for platforms in two incompatible encodings depending on
the endpoint. Build, pull and container-create want the string
`"linux/arm64"`; inspect, push, history and save want a JSON-encoded OCI
object. Sending the wrong one fails with
`400 failed to parse platform: invalid character 'l'`.

Write `"linux/arm64"` everywhere. `Docker::API::Platform` encodes whichever
form the endpoint in question wants.
