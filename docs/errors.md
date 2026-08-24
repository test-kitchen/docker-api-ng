# Errors

Everything this gem raises descends from `Docker::API::Error`. Nothing from
beneath the abstraction escapes: no `Errno`, no `SocketError`, no `OpenSSL`
exception and no `Net::` class reaches your rescue clause. The original is
always retained as `#cause`, so nothing is lost.

That is a deliberate difference from the `docker-api` gem, where
`Excon::Error::Socket` reaches callers and couples them to an HTTP library they
never chose.

## The hierarchy

```
Docker::API::Error
├── ConnectionError      the daemon could not be reached at all
├── TimeoutError         it accepted the connection but did not answer in time
├── ClientError          4xx
│   ├── BadRequest       400
│   ├── Unauthorized     401
│   ├── Forbidden        403
│   ├── NotFound         404
│   ├── NotModified      304
│   └── Conflict         409
├── ServerError          5xx
├── VersionUnsupported   the daemon speaks an API version this gem cannot use
└── StreamError          a response stream was malformed or truncated
```

`NotModified` is grouped with the client errors rather than treated as a
redirect because that is the meaning Docker gives it: starting an
already-running container returns 304.

## What an error carries

```ruby
begin
  client.containers.get("missing")
rescue Docker::API::Error => e
  e.operation   #=> "container_inspect"
  e.status      #=> 404
  e.response    #=> #<Docker::API::Response status=404 bytes=42>
  e.message     #=> "container_inspect failed (HTTP 404): No such container: missing"
  e.cause       #=> the underlying exception, when there was one
end
```

The message is composed from what was attempted, the status, and the daemon's
own `message` field. When the body is not JSON the raw body is used instead,
because an unparsed body still helps a human more than nothing does.

## Rescuing well

Rescue the narrowest thing that describes what you are handling:

```ruby
# Absence is a normal answer to a question.
container = client.containers.find("web")   # nil rather than an exception

# A name collision usually means somebody else won a race.
begin
  client.networks.create("shared")
rescue Docker::API::Conflict
  client.networks.get("shared")
end

# Connection and timeout failures are the ones worth retrying.
begin
  client.system.info
rescue Docker::API::ConnectionError, Docker::API::TimeoutError => e
  retry if (attempts += 1) < 3
  raise
end
```

Retrying a `ClientError` is almost always wrong: the request was malformed or
the object was not there, and it will not be there in a second.

## Build failures are not HTTP failures

The daemon reports a failed build inside a `200` response, as an `error` key in
the JSON-lines stream. Anything that only checks the status code concludes the
build succeeded. `Images#build` reads the stream and raises, so a build failure
is an exception like any other.

## Streaming errors

When a streaming request fails, the error response is buffered and raised
rather than handed to your block. Your block only ever sees output.
