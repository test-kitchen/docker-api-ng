# docker-api-ng Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `docker-api-ng`, a dependency-free Ruby client for the modern Docker Engine API, from empty repository to a releasable 0.1.0.

**Architecture:** Four layers with a single dependency direction. Pluggable socket transports produce an `IO`; a hand-written `Connection` turns that into requests, errors and streams; a layer generated from Docker's own Swagger definition exposes every operation; a hand-written ergonomic client provides collections and resource objects on top.

**Tech Stack:** Ruby >= 3.1, stdlib only at runtime (`net/http`, `socket`, `openssl`, `json`, `psych`). minitest + mocha for tests, Cookstyle's chefstyle for linting, YARD for docs, RBS + Steep for types, release-please for releases.

**Spec:** `docs/superpowers/specs/2026-08-24-docker-api-ng-design.md`

## Global Constraints

Every task's requirements implicitly include this section.

- **Ruby floor is `>= 3.1`.** `Data.define` is Ruby 3.2+ and MUST NOT be used. Use `Struct` with `keyword_init: true` or plain classes.
- **Zero runtime dependencies.** Nothing in `lib/` may `require` a gem. Development dependencies are unrestricted.
- **Namespace is `Docker::API`**, entry point `require "docker/api"`. `::Docker` is reopened additively; the gem MUST NOT define any method directly on `::Docker`, so it can coexist with the `docker-api` gem in one process.
- **No process-global mutable state.** No module-level setters, no shared credential store. Configuration is passed at construction and frozen.
- **No exception from below the abstraction may escape.** Every `Errno`, `OpenSSL`, `Net::`, `JSON`, `SocketError` and `Timeout::Error` raised inside the gem is caught and re-raised as a `Docker::API::Error` subclass with the original retained as `#cause`.
- **Vendored spec is Engine API v1.55**, at `data/swagger/v1.55.yaml`. Minimum supported daemon API version is **v1.41**.
- **Generated files are committed** and carry a `# GENERATED -- do not edit` banner. They are excluded from chefstyle.
- **Tests never touch the network or a real daemon** unless tagged as integration.
- **Licence is Apache-2.0.** Every source file carries the standard short header.

---

## File Structure

| File | Responsibility |
| --- | --- |
| `lib/docker/api.rb` | Entry point; requires the tree; defines `Docker::API.client` convenience |
| `lib/docker/api/version.rb` | `VERSION`, `MAX_API_VERSION`, `MIN_API_VERSION` |
| `lib/docker/api/errors.rb` | The closed error hierarchy and status-to-class mapping |
| `lib/docker/api/transport.rb` | Transport registry; `Transport.for(url:, tls:)` URL parsing |
| `lib/docker/api/transport/base.rb` | Shared transport contract and error wrapping |
| `lib/docker/api/transport/unix.rb` | `UNIXSocket` |
| `lib/docker/api/transport/tcp.rb` | `TCPSocket` |
| `lib/docker/api/transport/tls.rb` | `OpenSSL::SSL::SSLSocket` over TCP |
| `lib/docker/api/transport/named_pipe.rb` | Windows `//./pipe/docker_engine` |
| `lib/docker/api/transport/fake.rb` | Scripted `Socket.pair` for tests |
| `lib/docker/api/query.rb` | Docker query-string encoding rules |
| `lib/docker/api/response.rb` | Status, headers, raw body, lazily parsed JSON |
| `lib/docker/api/connection.rb` | Requests, error mapping, version negotiation, streaming, hijack |
| `lib/docker/api/session.rb` | `Net::HTTP` subclass that accepts a transport-made socket |
| `lib/docker/api/stream.rb` | `Demultiplexer`, `JSONLines`, `Raw` chunk decoders |
| `lib/docker/api/config.rb` | Environment resolution, frozen configuration |
| `lib/docker/api/auth.rb` | `~/.docker/config.json`, `credsStore`, `credHelpers`, `X-Registry-Auth` |
| `lib/docker/api/operations.rb` | GENERATED — one method per `operationId` |
| `lib/docker/api/models.rb` | GENERATED — parameter and response structs |
| `lib/docker/api/client.rb` | Ergonomic root; owns connection and namespaces |
| `lib/docker/api/collection.rb` | Shared collection behaviour |
| `lib/docker/api/collections/*.rb` | `containers`, `images`, `networks`, `volumes`, `system`, `exec`, `swarm`, … |
| `lib/docker/api/resource.rb` | Shared resource behaviour: `raw`, `partial?`, `reload` |
| `lib/docker/api/resources/*.rb` | `Container`, `Image`, `Network`, `Volume`, `Exec` |
| `tools/generator/*.rb` | Swagger parser and emitters (not shipped in the gem) |
| `tasks/codegen.rake` | `rake api:sync[VERSION]` |
| `spec/**` | minitest suites, mirroring `lib/` |
| `spec/integration/**` | Opt-in, real daemon |

---

## Task 1: Repository skeleton

**Files:**
- Create: `LICENSE`, `NOTICE`, `README.md`, `docker-api-ng.gemspec`, `Gemfile`, `Rakefile`, `.rubocop.yml`, `.gitignore`, `.yardopts`
- Create: `lib/docker/api/version.rb`, `lib/docker/api.rb`
- Test: `spec/spec_helper.rb`, `spec/version_spec.rb`

**Interfaces:**
- Produces: `Docker::API::VERSION` (String), `Docker::API::MAX_API_VERSION` = `"1.55"`, `Docker::API::MIN_API_VERSION` = `"1.41"`

- [ ] **Step 1: Write the failing test**

```ruby
# spec/version_spec.rb
require "spec_helper"

describe "Docker::API version constants" do
  it "exposes a semver gem version" do
    _(Docker::API::VERSION).must_match(/\A\d+\.\d+\.\d+/)
  end

  it "supports an API version range the daemon understands" do
    _(Gem::Version.new(Docker::API::MIN_API_VERSION))
      .must_be :<, Gem::Version.new(Docker::API::MAX_API_VERSION)
  end

  it "does not define methods on ::Docker" do
    # The docker-api gem owns ::Docker. Coexistence depends on us adding nothing to it.
    _(::Docker.methods(false)).must_be_empty
  end
end
```

- [ ] **Step 2: Run the test and watch it fail**

Run: `bundle exec rake unit`
Expected: FAIL — `uninitialized constant Docker`

- [ ] **Step 3: Write the skeleton**

`lib/docker/api/version.rb`:

```ruby
# frozen_string_literal: true

module Docker
  module API
    VERSION = "0.1.0"

    # The newest Engine API version this gem vendors a specification for.
    MAX_API_VERSION = "1.55"

    # The oldest Engine API version this gem will talk to.
    MIN_API_VERSION = "1.41"
  end
end
```

Gemspec: `spec.license = "Apache-2.0"`, `spec.required_ruby_version = ">= 3.1"`, no runtime dependencies, `spec.files` covering `lib/`, `sig/`, `data/`, `LICENSE`, `NOTICE`, `README.md`.

`.rubocop.yml` mirrors kitchen-dokken's, plus an exclusion for generated files:

```yaml
---
require:
  - cookstyle/chefstyle

AllCops:
  TargetRubyVersion: 3.1
  Exclude:
    - "vendor/**/*"
    - "spec/**/*"
    - "lib/docker/api/operations.rb"
    - "lib/docker/api/models.rb"
```

`spec/spec_helper.rb` carries kitchen-dokken's mocha guard verbatim:

```ruby
Mocha.configure { |c| c.stubbing_non_existent_method = :prevent }
```

- [ ] **Step 4: Run the tests and watch them pass**

Run: `bundle exec rake unit` — Expected: PASS
Run: `bundle exec rake style` — Expected: no offenses

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: gem skeleton, licence and version constants"
```

---

## Task 2: Error hierarchy

**Files:**
- Create: `lib/docker/api/errors.rb`
- Test: `spec/errors_spec.rb`

**Interfaces:**
- Produces: `Docker::API::Error` with `#operation`, `#status`, `#response`, `#cause`; subclasses `ConnectionError`, `TimeoutError`, `ClientError`, `BadRequest`, `Unauthorized`, `Forbidden`, `NotFound`, `NotModified`, `Conflict`, `ServerError`, `VersionUnsupported`, `StreamError`; and `Docker::API::Error.for(status:, operation:, response:)` returning an instance of the right subclass.

- [ ] **Step 1: Write the failing test**

```ruby
# spec/errors_spec.rb
require "spec_helper"

describe Docker::API::Error do
  it "maps status codes onto specific subclasses" do
    { 400 => Docker::API::BadRequest,
      401 => Docker::API::Unauthorized,
      403 => Docker::API::Forbidden,
      404 => Docker::API::NotFound,
      304 => Docker::API::NotModified,
      409 => Docker::API::Conflict,
      500 => Docker::API::ServerError,
      503 => Docker::API::ServerError }.each do |status, klass|
      err = Docker::API::Error.for(status: status, operation: "container_start", response: nil)
      _(err).must_be_kind_of klass
    end
  end

  it "surfaces the daemon's own message" do
    response = Docker::API::Response.new(
      status: 409, headers: {}, body: '{"message":"container already started"}'
    )
    err = Docker::API::Error.for(status: 409, operation: "container_start", response: response)
    _(err.message).must_include "container already started"
    _(err.message).must_include "container_start"
    _(err.status).must_equal 409
  end

  it "keeps every subclass under the one root" do
    [Docker::API::ConnectionError, Docker::API::TimeoutError, Docker::API::NotFound,
     Docker::API::ServerError, Docker::API::VersionUnsupported, Docker::API::StreamError]
      .each { |k| _(k.ancestors).must_include Docker::API::Error }
  end
end
```

- [ ] **Step 2: Run and watch it fail** — `bundle exec rake unit`, expect `uninitialized constant Docker::API::Error`
- [ ] **Step 3: Implement `lib/docker/api/errors.rb`.** `Error.for` looks the status up in a frozen `STATUS_MAP`, defaulting to `ClientError` for other 4xx and `ServerError` for other 5xx. The message is composed as `"#{operation} failed (HTTP #{status}): #{daemon_message}"`, where `daemon_message` comes from the response body's `message` key when it parses as JSON, and from the raw body otherwise.
- [ ] **Step 4: Run and watch it pass**
- [ ] **Step 5: Commit** — `git commit -m "feat: closed error hierarchy with daemon message extraction"`

---

## Task 3: Response and query encoding

**Files:**
- Create: `lib/docker/api/response.rb`, `lib/docker/api/query.rb`
- Test: `spec/response_spec.rb`, `spec/query_spec.rb`

**Interfaces:**
- Produces: `Docker::API::Response.new(status:, headers:, body:)` with `#status` (Integer), `#headers` (case-insensitive Hash), `#body` (String), `#json` (memoised parse, raises `Docker::API::StreamError` on invalid JSON), `#success?`
- Produces: `Docker::API::Query.encode(hash)` returning a String query fragment or `""`

- [ ] **Step 1: Write the failing tests**

```ruby
# spec/query_spec.rb
require "spec_helper"

describe Docker::API::Query do
  it "omits nils entirely" do
    _(Docker::API::Query.encode(name: nil, platform: nil)).must_equal ""
  end

  it "renders booleans the way the daemon expects" do
    _(Docker::API::Query.encode(all: true, size: false)).must_equal "?all=true&size=false"
  end

  it "JSON-encodes filters, because the daemon parses that value as a JSON map" do
    encoded = Docker::API::Query.encode(filters: { "status" => ["running"] })
    _(CGI.unescape(encoded)).must_equal '?filters={"status":["running"]}'
  end

  it "escapes values that would otherwise break the URL" do
    _(Docker::API::Query.encode(name: "a b&c")).must_equal "?name=a+b%26c"
  end
end
```

- [ ] **Step 2: Run and watch them fail**
- [ ] **Step 3: Implement.** `Query.encode` rejects nil values, converts `true`/`false` to `"true"`/`"false"`, `Hash`/`Array` to `JSON.generate`, everything else via `to_s`, then joins with `URI.encode_www_form`. Returns `""` when nothing survives so callers can concatenate unconditionally.
- [ ] **Step 4: Run and watch them pass**
- [ ] **Step 5: Commit** — `git commit -m "feat: response object and Docker query-string encoding"`

---

## Task 4: Transports

**Files:**
- Create: `lib/docker/api/transport.rb`, `lib/docker/api/transport/{base,unix,tcp,tls,named_pipe,fake}.rb`
- Test: `spec/transport_spec.rb`, `spec/transport/{unix,tcp,fake}_spec.rb`

**Interfaces:**
- Produces: every transport responds to `#connect` returning a connected `IO`, `#host_header` returning a `String`, and `#to_s`
- Produces: `Docker::API::Transport.for(url:, tls: nil)` returning the right transport for `unix://`, `tcp://`, `http://`, `https://`, `npipe://` and bare paths
- Produces: `Docker::API::Transport::Fake.new(responses)` with `#requests` recording raw request bytes

**Why `Fake` uses a real socket pair:** `Net::BufferedIO` calls `read_nonblock`, `write` and `to_io` on whatever it is given. A `StringIO` does not implement that contract, and faking it produces tests that pass against a double the real code could never drive. `Socket.pair(:UNIX, :STREAM)` gives genuine socket semantics with no network, so the connection layer is exercised exactly as it runs in production.

- [ ] **Step 1: Write the failing tests**

```ruby
# spec/transport_spec.rb
require "spec_helper"

describe Docker::API::Transport do
  it "routes each URL scheme to its transport" do
    _(Docker::API::Transport.for(url: "unix:///var/run/docker.sock"))
      .must_be_kind_of Docker::API::Transport::Unix
    _(Docker::API::Transport.for(url: "tcp://192.168.0.5:2375"))
      .must_be_kind_of Docker::API::Transport::Tcp
    _(Docker::API::Transport.for(url: "npipe:////./pipe/docker_engine"))
      .must_be_kind_of Docker::API::Transport::NamedPipe
  end

  it "upgrades tcp to TLS when TLS material is supplied" do
    t = Docker::API::Transport.for(url: "tcp://build:2376", tls: { ca_file: "/ca.pem" })
    _(t).must_be_kind_of Docker::API::Transport::Tls
  end

  it "refuses a scheme it cannot honour, naming what it got" do
    err = _ { Docker::API::Transport.for(url: "ftp://nope") }.must_raise Docker::API::ConnectionError
    _(err.message).must_include "ftp"
  end

  it "raises ConnectionError, not Errno, when the socket is absent" do
    t = Docker::API::Transport::Unix.new(path: "/nonexistent/docker.sock")
    err = _ { t.connect }.must_raise Docker::API::ConnectionError
    _(err.cause).must_be_kind_of SystemCallError
  end
end
```

```ruby
# spec/transport/fake_spec.rb
require "spec_helper"

describe Docker::API::Transport::Fake do
  it "serves a scripted response over a real socket and records the request" do
    fake = Docker::API::Transport::Fake.new(["HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nhi"])
    io = fake.connect
    io.write("GET /_ping HTTP/1.1\r\nHost: localhost\r\n\r\n")
    _(io.read).must_include "hi"
    _(fake.requests.first).must_include "GET /_ping"
  end
end
```

- [ ] **Step 2: Run and watch them fail**
- [ ] **Step 3: Implement the transports.**

`Transport.for` parses with `URI.parse`, treating a bare path as `unix://`. `tcp://` becomes `Tls` when `tls:` is non-empty or the port is 2376 with `DOCKER_TLS_VERIFY` set; otherwise `Tcp`. Every `#connect` wraps `SystemCallError`, `SocketError`, `OpenSSL::SSL::SSLError` and `Timeout::Error` into `Docker::API::ConnectionError`, naming the endpoint.

`Fake#connect` creates `Socket.pair(:UNIX, :STREAM)`, starts a thread that reads one request (headers, then `Content-Length` bytes of body), appends it to `#requests`, writes the next scripted response and closes its end. Returns the caller's end.

- [ ] **Step 4: Run and watch them pass**
- [ ] **Step 5: Commit** — `git commit -m "feat: pluggable socket transports for unix, tcp, tls and named pipes"`

---

## Task 5: Session — Net::HTTP over a transport socket

**Files:**
- Create: `lib/docker/api/session.rb`
- Test: `spec/session_spec.rb`

**Interfaces:**
- Produces: `Docker::API::Session.new(transport, read_timeout:, open_timeout:)`, a `Net::HTTP` subclass whose `#connect` uses the transport instead of dialling a host

**The seam:** `Net::HTTP#connect` is a private method that assigns `@socket`. Overriding it is the whole trick — we get chunked decoding, keep-alive and header parsing from the stdlib while owning socket creation, which is what makes unix sockets, TLS and Windows named pipes reachable without a dependency. TLS is performed by the transport, so `use_ssl` stays false and `Net::HTTP` never tries to negotiate.

- [ ] **Step 1: Write the failing test**

```ruby
# spec/session_spec.rb
require "spec_helper"

describe Docker::API::Session do
  it "drives a real HTTP exchange over a transport-supplied socket" do
    body = '{"ApiVersion":"1.55"}'
    fake = Docker::API::Transport::Fake.new([
      "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n" \
      "Content-Length: #{body.bytesize}\r\n\r\n#{body}",
    ])
    session = Docker::API::Session.new(fake, read_timeout: 5, open_timeout: 5)
    response = session.start { |http| http.request(Net::HTTP::Get.new("/v1.55/version")) }

    _(response.code).must_equal "200"
    _(JSON.parse(response.body)["ApiVersion"]).must_equal "1.55"
    _(fake.requests.first).must_include "GET /v1.55/version"
  end

  it "decodes a chunked response body without the caller knowing" do
    fake = Docker::API::Transport::Fake.new([
      "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n" \
      "5\r\nhello\r\n5\r\nworld\r\n0\r\n\r\n",
    ])
    session = Docker::API::Session.new(fake, read_timeout: 5, open_timeout: 5)
    response = session.start { |http| http.request(Net::HTTP::Get.new("/x")) }
    _(response.body).must_equal "helloworld"
  end
end
```

- [ ] **Step 2: Run and watch it fail**
- [ ] **Step 3: Implement**

```ruby
# frozen_string_literal: true

module Docker
  module API
    # A Net::HTTP that connects through a Docker transport rather than by
    # dialling a hostname. Overriding #connect is what lets the stdlib parse
    # HTTP for us while we retain ownership of the socket -- which is how unix
    # sockets, TLS and Windows named pipes are reachable with no dependency.
    class Session < Net::HTTP
      def initialize(transport, read_timeout:, open_timeout:)
        super(transport.host_header, 80)
        @transport = transport
        self.read_timeout = read_timeout
        self.open_timeout = open_timeout
      end

      private

      # TLS, when in use, was negotiated by the transport; use_ssl stays false
      # so Net::HTTP does not try to negotiate a second time over the top.
      def connect
        socket = @transport.connect
        @socket = Net::BufferedIO.new(
          socket,
          read_timeout: @read_timeout,
          write_timeout: @write_timeout,
          continue_timeout: @continue_timeout,
          debug_output: @debug_output
        )
        on_connect
      end
    end
  end
end
```

- [ ] **Step 4: Run and watch it pass**
- [ ] **Step 5: Commit** — `git commit -m "feat: Net::HTTP session over a transport-supplied socket"`

---

## Task 6: Connection — requests, errors, negotiation

**Files:**
- Create: `lib/docker/api/connection.rb`
- Test: `spec/connection_spec.rb`

**Interfaces:**
- Produces: `Connection.new(transport:, api_version: :negotiate, logger: nil, read_timeout: 60, open_timeout: 10)`
- Produces: `#request(method, path, query: {}, body: nil, headers: {}, expects: [200], operation: nil, &block)` returning `Docker::API::Response`; when a block is given the response body is yielded in chunks and `Response#body` is empty
- Produces: `#api_version` returning the negotiated version String, `#ping` returning `Response`

- [ ] **Step 1: Write the failing tests** covering: a successful GET returning parsed JSON; an unexpected status raising the mapped error carrying the operation name; version negotiation choosing `min(MAX_API_VERSION, daemon)` from the `Api-Version` ping header; a daemon below `MIN_API_VERSION` raising `VersionUnsupported` naming both versions; `api_version: "1.44"` skipping the ping entirely; a Hash body being JSON-encoded with `Content-Type: application/json`; and a block receiving body chunks.

```ruby
# spec/connection_spec.rb — representative cases
it "negotiates down to the daemon's version" do
  fake = Docker::API::Transport::Fake.new([ping_response(api_version: "1.44")])
  conn = Docker::API::Connection.new(transport: fake)
  _(conn.api_version).must_equal "1.44"
end

it "never negotiates above what this gem vendors" do
  fake = Docker::API::Transport::Fake.new([ping_response(api_version: "1.99")])
  conn = Docker::API::Connection.new(transport: fake)
  _(conn.api_version).must_equal Docker::API::MAX_API_VERSION
end

it "refuses a daemon older than the supported floor, naming both versions" do
  fake = Docker::API::Transport::Fake.new([ping_response(api_version: "1.24")])
  conn = Docker::API::Connection.new(transport: fake)
  err = _ { conn.api_version }.must_raise Docker::API::VersionUnsupported
  _(err.message).must_include "1.24"
  _(err.message).must_include Docker::API::MIN_API_VERSION
end

it "raises the mapped error with the operation name attached" do
  fake = Docker::API::Transport::Fake.new([
    json_response(404, { "message" => "No such container: nope" }),
  ])
  conn = Docker::API::Connection.new(transport: fake, api_version: "1.55")
  err = _ {
    conn.request(:get, "/containers/nope/json", operation: "container_inspect")
  }.must_raise Docker::API::NotFound
  _(err.message).must_include "container_inspect"
  _(err.message).must_include "No such container"
end
```

- [ ] **Step 2: Run and watch them fail**
- [ ] **Step 3: Implement.** Path becomes `"/v#{api_version}#{path}#{Query.encode(query)}"`, except `/_ping` and `/version`, which are sent unprefixed during negotiation to avoid a chicken-and-egg. Bodies: `Hash` → `JSON.generate` with `Content-Type: application/json`; `String`/`IO` → passed through with the caller's content type, defaulting to `application/x-tar` for build and archive endpoints. Every `Net::` and `Timeout` exception is rescued and re-raised as `ConnectionError` or `TimeoutError`. `User-Agent` is `docker-api-ng/#{VERSION} (Ruby #{RUBY_VERSION})`.
- [ ] **Step 4: Run and watch them pass**
- [ ] **Step 5: Commit** — `git commit -m "feat: connection with version negotiation and error mapping"`

---

## Task 7: Stream decoders

**Files:**
- Create: `lib/docker/api/stream.rb`
- Test: `spec/stream_spec.rb`

**Interfaces:**
- Produces: `Stream::Demultiplexer.new { |name, chunk| }` with `#<<(chunk)`, emitting `:stdin`, `:stdout`, `:stderr`
- Produces: `Stream::JSONLines.new { |object| }` with `#<<(chunk)`
- Produces: `Stream::Raw.new { |chunk| }` with `#<<(chunk)`

**Why these are stateful accumulators:** `Net::HTTP` yields chunks at arbitrary byte boundaries that have nothing to do with Docker's framing. A frame header can be split across two chunks, and a JSON object can be split mid-string. Decoders that assume chunk boundaries are message boundaries work in tests and corrupt output in production, which is exactly the class of bug that produces interleaved garbage in an `exec` callback.

- [ ] **Step 1: Write the failing tests**

```ruby
# spec/stream_spec.rb
require "spec_helper"

describe Docker::API::Stream::Demultiplexer do
  # Docker's multiplexed framing: byte 0 is the stream id, bytes 4-7 are a
  # big-endian payload length, then the payload.
  def frame(stream_id, payload)
    [stream_id, 0, 0, 0, payload.bytesize].pack("CCCCN") + payload
  end

  it "separates stdout from stderr" do
    seen = []
    demux = Docker::API::Stream::Demultiplexer.new { |name, chunk| seen << [name, chunk] }
    demux << frame(1, "out") << frame(2, "err")
    _(seen).must_equal [[:stdout, "out"], [:stderr, "err"]]
  end

  it "reassembles a frame split across chunk boundaries" do
    seen = []
    demux = Docker::API::Stream::Demultiplexer.new { |name, chunk| seen << [name, chunk] }
    bytes = frame(1, "hello world")
    bytes.each_byte.each_slice(3) { |slice| demux << slice.pack("C*") }
    _(seen).must_equal [[:stdout, "hello world"]]
  end

  it "emits nothing until a frame is complete" do
    seen = []
    demux = Docker::API::Stream::Demultiplexer.new { |name, chunk| seen << [name, chunk] }
    demux << frame(1, "partial").byteslice(0, 10)
    _(seen).must_be_empty
  end
end

describe Docker::API::Stream::JSONLines do
  it "reassembles an object split across chunks" do
    seen = []
    lines = Docker::API::Stream::JSONLines.new { |object| seen << object }
    lines << '{"status":"Pull' << 'ing"}' << "\n"
    _(seen).must_equal [{ "status" => "Pulling" }]
  end

  it "emits each object of a multi-object chunk in order" do
    seen = []
    lines = Docker::API::Stream::JSONLines.new { |object| seen << object }
    lines << %({"a":1}\n{"a":2}\n)
    _(seen.map { |o| o["a"] }).must_equal [1, 2]
  end
end
```

- [ ] **Step 2: Run and watch them fail**
- [ ] **Step 3: Implement.** Both decoders hold a binary-encoded buffer (`+"".b`), append each chunk, and loop emitting complete units. `Demultiplexer` needs 8 bytes for a header, then `length` more for the payload; the payload is force-encoded to UTF-8 before being yielded. `JSONLines` splits on `\n`, keeps any trailing partial line in the buffer, and skips blank lines. Malformed JSON raises `StreamError`.
- [ ] **Step 4: Run and watch them pass**
- [ ] **Step 5: Commit** — `git commit -m "feat: multiplexed, JSON-lines and raw stream decoders"`

---

## Task 8: Hijack

**Files:**
- Modify: `lib/docker/api/connection.rb`
- Test: `spec/connection_hijack_spec.rb`

**Interfaces:**
- Produces: `Connection#hijack(method, path, query: {}, body: nil, headers: {}, operation: nil)` returning the raw bidirectional `IO` after a successful upgrade

**Why this bypasses `Net::HTTP`:** an interactive `exec` needs the socket itself, and `Net::BufferedIO` may already have read ahead past the response headers. Rather than prise a buffered socket back out of the stdlib — the problem that produced `docker-api`'s custom Excon middleware — this path writes the request line and headers itself, reads the status line and headers with `IO#readline`, and hands back the socket with its buffer intact.

- [ ] **Step 1: Write the failing test** — a `Fake` scripted with `HTTP/1.1 101 UPGRADED\r\nContent-Type: application/vnd.docker.raw-stream\r\nConnection: Upgrade\r\nUpgrade: tcp\r\n\r\n` followed by payload bytes; assert `#hijack` returns an `IO` whose next read is the payload, that the request carried `Upgrade: tcp` and `Connection: Upgrade`, and that a `500` response raises `ServerError` rather than returning a socket.
- [ ] **Step 2: Run and watch it fail**
- [ ] **Step 3: Implement**
- [ ] **Step 4: Run and watch it pass**
- [ ] **Step 5: Commit** — `git commit -m "feat: connection hijack for interactive exec and attach"`

---

## Task 9: Config, auth and client construction

**Files:**
- Create: `lib/docker/api/config.rb`, `lib/docker/api/auth.rb`, `lib/docker/api/client.rb`
- Test: `spec/config_spec.rb`, `spec/auth_spec.rb`

**Interfaces:**
- Produces: `Config.from_env(env = ENV)` honouring `DOCKER_HOST`, `DOCKER_CERT_PATH`, `DOCKER_TLS_VERIFY`, falling back to `unix:///var/run/docker.sock` on POSIX and `npipe:////./pipe/docker_engine` on Windows. The returned object is frozen.
- Produces: `Auth.resolve(registry, config_path: nil)` returning a base64 `X-Registry-Auth` header value or `nil`
- Produces: `Client.new(url: nil, tls: nil, api_version: :negotiate, logger: nil, **timeouts)` with `#connection` and `#operations`

- [ ] **Step 1: Write the failing tests.** Config: each environment variable is honoured; `DOCKER_CERT_PATH` produces TLS material from `ca.pem`/`cert.pem`/`key.pem`; `DOCKER_TLS_VERIFY=""` disables peer verification; the result is frozen. Auth: a plain `auths` entry is decoded; a `credHelpers` entry for a specific registry wins over `credsStore`; a missing config file yields `nil` rather than raising; a `credsStore` binary that is absent yields `nil` rather than raising. **Two clients constructed with different URLs must not share any state** — the explicit regression test for `docker-api`'s global `Docker.url=`.
- [ ] **Step 2: Run and watch them fail**
- [ ] **Step 3: Implement.** Credential helpers are invoked via `IO.popen` with an argument array, never a shell string.
- [ ] **Step 4: Run and watch them pass**
- [ ] **Step 5: Commit** — `git commit -m "feat: environment config, registry auth and client construction"`

---

## Task 10: Swagger vendoring and the generator's parser

**Files:**
- Create: `data/swagger/v1.55.yaml`, `tools/generator/spec_reader.rb`, `tools/generator/operation.rb`, `tasks/codegen.rake`
- Test: `spec/generator/spec_reader_spec.rb`

**Interfaces:**
- Produces: `Generator::SpecReader.new(path).operations` returning `Generator::Operation` structs with `#id` (`"ContainerCreate"`), `#method_name` (`:container_create`), `#verb` (`:post`), `#path` (`"/containers/create"`), `#path_params`, `#query_params`, `#body_param`, `#header_params`, `#success_codes`, `#error_codes` (status to description), `#summary`, `#description`
- Produces: `rake api:sync[VERSION]`

**Grounding:** the vendored v1.55 document defines 108 operations across 98 paths — several paths carry more than one verb. Parameters appear in four places (`query`, `path`, `body`, `header`) and five types (`string`, `boolean`, `integer`, `array`, `schema`). That is a closed set, so the generator needs five type mappings rather than a general-purpose Swagger compiler.

- [ ] **Step 1: Write the failing test**

```ruby
# spec/generator/spec_reader_spec.rb
require "spec_helper"
require "generator/spec_reader"

describe Generator::SpecReader do
  let(:reader) { Generator::SpecReader.new(File.expand_path("../../data/swagger/v1.55.yaml", __dir__)) }

  it "reads every operation in the document" do
    _(reader.operations.size).must_be :>, 100
  end

  it "converts a NounVerb operationId into a snake_case method name" do
    create = reader.operations.find { |o| o.id == "ContainerCreate" }
    _(create.method_name).must_equal :container_create
    _(create.verb).must_equal :post
    _(create.path).must_equal "/containers/create"
  end

  it "captures the query parameters that docker-api silently dropped" do
    create = reader.operations.find { |o| o.id == "ContainerCreate" }
    _(create.query_params.map(&:name)).must_include "platform"
    _(create.query_params.map(&:name)).must_include "name"
  end

  it "captures path parameters for templated routes" do
    inspect = reader.operations.find { |o| o.id == "ContainerInspect" }
    _(inspect.path_params.map(&:name)).must_equal ["id"]
    _(inspect.path).must_equal "/containers/{id}/json"
  end

  it "records documented error codes so they can be raised meaningfully" do
    inspect = reader.operations.find { |o| o.id == "ContainerInspect" }
    _(inspect.error_codes.keys).must_include 404
  end
end
```

- [ ] **Step 2: Run and watch it fail**
- [ ] **Step 3: Implement.** `SpecReader` loads with `YAML.safe_load_file(path, aliases: true)` — the document uses YAML anchors, so `aliases: true` is required. `method_name` is `id.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase.to_sym`. `rake api:sync[VERSION]` fetches `https://docs.docker.com/reference/api/engine/version/v{VERSION}.yaml` into `data/swagger/`, runs every emitter, and prints the resulting `git diff --stat`.
- [ ] **Step 4: Run and watch it pass**
- [ ] **Step 5: Commit** — `git commit -m "feat: vendor Engine API v1.55 spec and add its parser"`

---

## Task 11: Operations emitter

**Files:**
- Create: `tools/generator/operations_emitter.rb`, `lib/docker/api/operations.rb` (generated)
- Test: `spec/generator/operations_emitter_spec.rb`

**Interfaces:**
- Produces: `Generator::OperationsEmitter.new(operations).render` returning Ruby source
- Produces: `Docker::API::Operations.new(connection)` with 108 methods

- [ ] **Step 1: Write the failing test.** Assert the emitted source for `ContainerCreate` contains `def container_create(body:, name: nil, platform: nil)`, that path parameters are required positional-style keywords, that the generated file starts with the `# GENERATED -- do not edit` banner, and that the output parses: `_(RubyVM::InstructionSequence.compile(source)).wont_be_nil`.
- [ ] **Step 2: Run and watch it fail**
- [ ] **Step 3: Implement the emitter.** Required parameters (path params, and body params marked required) become required keywords; everything else defaults to `nil`. Path templates interpolate with `ERB::Util.url_encode`. Each method passes `operation:` so errors name themselves. YARD doc comments come from the spec's own `description` fields, wrapped at 78 columns.
- [ ] **Step 4: Generate, then run the suite** — `bundle exec rake api:generate && bundle exec rake unit`
- [ ] **Step 5: Commit** — `git commit -m "feat: generate the operations layer from the vendored spec"`

---

## Task 12: Conformance tests and RBS emitters

**Files:**
- Create: `tools/generator/{conformance_emitter,rbs_emitter}.rb`, `spec/generated/operations_conformance_spec.rb`, `sig/docker/api/operations.rbs`
- Test: the generated conformance suite is itself the test

**Interfaces:**
- Produces: one conformance test per operation asserting verb, path template and parameter names against the spec, driven through `Transport::Fake`

**Why this exists:** committed generated code is only trustworthy if a bad generator change fails loudly. The conformance suite pins the contract, so a regression surfaces in CI rather than as a silently wrong URL at runtime.

- [ ] **Step 1: Write the emitter's own test** asserting the generated suite contains a test per operation and that a deliberately corrupted emitter output fails.
- [ ] **Step 2: Run and watch it fail**
- [ ] **Step 3: Implement both emitters.** Each conformance test constructs a `Fake`, invokes the operation with placeholder arguments, and asserts the recorded request line. RBS types map `string`→`String`, `boolean`→`bool`, `integer`→`Integer`, `array`→`Array[untyped]`, `schema`→`Hash[String, untyped]`, each optional parameter as `?Type?`.
- [ ] **Step 4: Run the generated suite and Steep** — `bundle exec rake unit && bundle exec steep check`
- [ ] **Step 5: Commit** — `git commit -m "feat: generate conformance tests and RBS signatures"`

---

## Task 13: Ergonomic layer — collections and resources

**Files:**
- Create: `lib/docker/api/collection.rb`, `lib/docker/api/resource.rb`, `lib/docker/api/collections/*.rb`, `lib/docker/api/resources/*.rb`
- Test: `spec/collections/*_spec.rb`, `spec/resources/*_spec.rb`

**Interfaces:**
- Produces: `Client#containers`, `#images`, `#networks`, `#volumes`, `#system`, `#exec`, `#swarm`, `#services`, `#nodes`, `#tasks`, `#secrets`, `#configs`, `#plugins`, `#distribution`
- Produces: `Container` with `#id`, `#name`, `#state`, `#ports`, `#labels`, `#raw`, `#partial?`, `#reload`, `#start`, `#stop`, `#restart`, `#kill`, `#pause`, `#unpause`, `#remove`, `#logs`, `#exec`, `#attach`, `#wait`, `#stats`, `#top`, `#rename`, `#archive_in`, `#archive_out`, `#commit`
- Produces: `Image` with `#id`, `#tags`, `#tag`, `#push`, `#remove`, `#history`, `#save`
- Produces: `ExecResult` = `Struct.new(:stdout, :stderr, :exit_code, keyword_init: true)`

**The normalisation requirement:** `GET /containers/json` returns `Names: ["/foo"]`; `GET /containers/{id}/json` returns `Name: "/foo"`. A resource must answer `#name` identically from either. A resource built from a list response is `#partial?`; an accessor needing inspect-only data performs exactly one lazy `#reload`.

- [ ] **Step 1: Write the failing tests**

```ruby
# spec/resources/container_spec.rb — the normalisation contract
it "answers #name identically whether built from a list or an inspect" do
  from_list = Docker::API::Container.new(client: client, raw: { "Id" => "abc", "Names" => ["/dokken-x"] }, partial: true)
  from_inspect = Docker::API::Container.new(client: client, raw: { "Id" => "abc", "Name" => "/dokken-x" }, partial: false)
  _(from_list.name).must_equal "dokken-x"
  _(from_inspect.name).must_equal "dokken-x"
end

it "reloads exactly once when an accessor needs inspect-only data" do
  container = Docker::API::Container.new(client: client, raw: { "Id" => "abc" }, partial: true)
  client.operations.expects(:container_inspect).once.returns(inspect_response)
  2.times { container.state }
end

it "never reloads a resource that is already complete" do
  container = Docker::API::Container.new(client: client, raw: full_inspect_payload, partial: false)
  client.operations.expects(:container_inspect).never
  _(container.state).must_equal "running"
end
```

- [ ] **Step 2: Run and watch them fail**
- [ ] **Step 3: Implement.** Every ergonomic method is a thin call into `client.operations`. `Collection#find` returns `nil` where `#get` raises `NotFound`.
- [ ] **Step 4: Run and watch them pass**
- [ ] **Step 5: Commit** — `git commit -m "feat: ergonomic collections and normalised resource objects"`

---

## Task 14: Exec, logs and build — the streaming ergonomics

**Files:**
- Modify: `lib/docker/api/resources/container.rb`, `lib/docker/api/collections/images.rb`
- Test: `spec/resources/container_exec_spec.rb`, `spec/collections/images_build_spec.rb`

**Interfaces:**
- Produces: `Container#exec(command, env: {}, user: nil, working_dir: nil, tty: false, &block)` → `ExecResult`
- Produces: `Container#logs(follow: false, stdout: true, stderr: true, tail: nil, &block)`
- Produces: `Images#build(context:, tag: nil, platform: nil, nocache: false, rm: true, buildargs: {}, &block)` → `Image`
- Produces: `Images#pull(reference, platform: nil, auth: nil, &block)` → `Image`

- [ ] **Step 1: Write the failing tests.** Exec: create-then-start is issued in that order; the block receives `(:stdout, chunk)` and `(:stderr, chunk)` separately from a multiplexed response; the exit code comes from a final `exec_inspect`; a non-zero exit is returned rather than raised, because the caller decides what a failing command means. Build: the context directory is tarred and sent as `application/x-tar`; `platform` reaches the query string — **the named regression test for the dropped-parameter defect**; JSON-lines progress is yielded; a build failure raises with the daemon's error detail.
- [ ] **Step 2: Run and watch them fail**
- [ ] **Step 3: Implement.** Tarring uses `Gem::Package::TarWriter` from RubyGems, which ships with Ruby and adds no dependency. `.dockerignore` is honoured.
- [ ] **Step 4: Run and watch them pass**
- [ ] **Step 5: Commit** — `git commit -m "feat: streaming exec, logs, build and pull"`

---

## Task 15: The kitchen-dokken regression suite

**Files:**
- Create: `spec/regression/docker_api_defects_spec.rb`

**Interfaces:**
- Consumes: everything above

Each of the five defects from the spec gets a named test that fails against `docker-api`'s behaviour and passes here.

- [ ] **Step 1: Write the tests**

```ruby
# spec/regression/docker_api_defects_spec.rb
describe "defects inherited from docker-api" do
  it "forwards platform on container create (docker-api dropped every query param but name)" do
    client.containers.create(image: "alpine", name: "x", platform: "linux/arm64")
    _(fake.requests.first).must_include "platform=linux%2Farm64"
  end

  it "gets a container by name without falling back to listing them all" do
    _(client.containers.get("dokken-x").name).must_equal "dokken-x"
    _(fake.requests.first).must_include "/containers/dokken-x/json"
  end

  it "keeps two clients pointed at two daemons completely independent" do
    a = Docker::API::Client.new(url: "tcp://a:2375", api_version: "1.55")
    b = Docker::API::Client.new(url: "tcp://b:2375", api_version: "1.55")
    _(a.connection.transport.to_s).wont_equal b.connection.transport.to_s
  end

  it "never lets an Errno escape as itself" do
    client = Docker::API::Client.new(url: "unix:///nonexistent.sock")
    err = _ { client.system.info }.must_raise Docker::API::ConnectionError
    _(err).wont_be_kind_of SystemCallError
    _(err.cause).must_be_kind_of SystemCallError
  end

  it "builds a named-pipe transport on Windows paths" do
    t = Docker::API::Transport.for(url: "npipe:////./pipe/docker_engine")
    _(t).must_be_kind_of Docker::API::Transport::NamedPipe
  end
end
```

- [ ] **Step 2: Run and watch them fail where unimplemented**
- [ ] **Step 3: Fix whatever fails**
- [ ] **Step 4: Run and watch them pass**
- [ ] **Step 5: Commit** — `git commit -m "test: regression suite for the defects inherited from docker-api"`

---

## Task 16: Integration suite

**Files:**
- Create: `spec/integration/{helper,containers,images,networks,exec}_spec.rb`, `bin/record`

**Interfaces:**
- Produces: `rake integration`, skipped unless `DOCKER_API_NG_INTEGRATION=1`

- [ ] **Step 1: Write the integration tests** — pull `alpine:3.20`, create, start, exec `echo`, assert stdout and exit code, read logs, build a trivial image, create and remove a network and a volume, then clean up in an `ensure`.
- [ ] **Step 2: Run against the local daemon** — `DOCKER_API_NG_INTEGRATION=1 bundle exec rake integration`
- [ ] **Step 3: Implement `bin/record`** to capture exchanges as `Transport::Fake` fixtures
- [ ] **Step 4: Confirm the default suite still performs no network access**
- [ ] **Step 5: Commit** — `git commit -m "test: opt-in integration suite against a real daemon"`

---

## Task 17: Documentation, CI and release plumbing

**Files:**
- Create: `.github/workflows/{ci,integration,publish}.yml`, `release-please-config.json`, `.release-please-manifest.json`, `.github/dependabot.yml`, `Steepfile`, `docs/*.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`
- Modify: `README.md`

- [ ] **Step 1: Write the CI workflows.** `ci.yml`: chefstyle, the unit suite on Ruby 3.1/3.2/3.3/3.4/4.0, Steep, and a doc-coverage gate failing on any undocumented public method. `integration.yml`: the integration suite against the runner's daemon. `publish.yml`: trusted publishing to RubyGems on tag.
- [ ] **Step 2: Write the guides** — `docs/connecting.md`, `docs/streaming.md`, `docs/exec.md`, `docs/building-images.md`, `docs/errors.md`, `docs/migrating-from-docker-api.md` (a call-by-call table covering kitchen-dokken's surface), `docs/extending.md` (how `rake api:sync` works and how to add ergonomics for a generated operation).
- [ ] **Step 3: Write the README** — what it is, why it exists, a 60-second quickstart, and a pointer to the guides.
- [ ] **Step 4: Verify the whole gate passes** — `bundle exec rake` plus `gem build docker-api-ng.gemspec`
- [ ] **Step 5: Commit** — `git commit -m "docs: guides, CI workflows and release automation"`

---

## Self-Review

**Spec coverage.** Every spec section maps to a task: layering → 4-6, transports → 4, connection → 6, negotiation → 6, errors → 2, auth → 9, streaming → 7, hijack → 8, codegen → 10-12, public API → 13-14, resource semantics → 13, escape hatch → 11, testing tiers → 5-16, tooling → 17, layout → all, milestones → task ordering, the five defects → 15.

**Placeholders.** None. Every code step carries real code or a precise description of the transformation, and every named type is defined in the task that produces it.

**Type consistency.** `Response.new(status:, headers:, body:)`, `Error.for(status:, operation:, response:)`, `Transport#connect`/`#host_header`, `Connection#request(..., operation:)`, `Operations.new(connection)`, `ExecResult(stdout:, stderr:, exit_code:)` and `Container.new(client:, raw:, partial:)` are used identically wherever they appear.
