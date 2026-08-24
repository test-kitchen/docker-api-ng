# Extending and upgrading

## How the generated layer is made

`data/swagger/v1.55.yaml` is a vendored copy of Docker's own Swagger 2.0
definition of the Engine API. Three emitters read it:

| Emitter | Output |
| --- | --- |
| `tools/generator/operations_emitter.rb` | `lib/docker/api/operations.rb` |
| `tools/generator/conformance_emitter.rb` | `spec/generated/operations_conformance_spec.rb` |
| `tools/generator/rbs_emitter.rb` | `sig/docker/api/operations.rbs` |

```console
$ bundle exec rake api:generate
```

The output is plain, committed Ruby — no `define_method`, no runtime
dispatch. Every method is spelled out so it can be read, grepped, documented by
YARD and stepped through in a debugger. A metaprogrammed layer would be shorter
to generate and considerably worse to live with.

Because the output is committed, installing the gem needs no toolchain.

## Upgrading to a new API version

```console
$ bundle exec rake api:sync[1.56]
$ git diff --stat
```

`api:sync` fetches the specification, updates `MAX_API_VERSION`, regenerates
everything, and prints the diff. Then read it:

- A new endpoint appears as a new method.
- A new parameter appears in a signature and in the RBS.
- A removed parameter vanishes, and `steep check` names every caller.
- A changed path or verb shows up as a failing conformance test.

`rake api:verify` fails if the committed files do not match what the
specification currently produces, so CI catches a hand-edit or a forgotten
regeneration.

## Adding an ergonomic wrapper

The generated layer is complete. The ergonomic layer is sugar, and it grows
when sugar is warranted — when there is normalisation to do, several calls to
sequence, or a stream to decode.

A wrapper is a thin call into `client.operations`:

```ruby
module Docker
  module API
    class Containers < Collection
      def restart_all(filters: nil)
        all(filters: filters).each(&:restart)
      end
    end
  end
end
```

Two rules keep the layers honest:

1. **The ergonomic layer never talks to the connection directly.** It goes
   through `operations`, so there is one place where requests are made.
2. **It never hides capability.** If a wrapper cannot express something the
   endpoint supports, that is a reason to widen the wrapper, not a reason for
   callers to have no way to say it.

## Adding a transport

A transport makes a socket. That is the whole contract:

```ruby
class MyTransport < Docker::API::Transport::Base
  def connect
    dial("my://endpoint") { SomeSocket.new(...) }
  end

  def host_header
    "localhost"
  end
end

Docker::API::Client.new(transport: MyTransport.new)
```

`dial` converts every way the operating system reports failure into
`Docker::API::ConnectionError`, which is what keeps `Errno` out of callers'
rescue clauses.

## Where the parameter names come from

Method and parameter names are derived from the specification's `operationId`
and parameter names:

- `ContainerCreate` becomes `container_create`
- `fromImage` becomes `from_image`
- `one-shot` becomes `one_shot`
- `X-Registry-Auth` becomes `x_registry_auth`
- `until` becomes `until_`, because Ruby will accept `def f(until: nil)` and
  then refuse to parse any reference to it
- Every body parameter becomes `body`, whatever the specification calls it —
  there are thirteen different names in v1.55

Renamed parameters say so in their generated documentation, naming the spelling
that goes on the wire.
