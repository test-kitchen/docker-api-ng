# Streaming

The Engine API streams in three different wire formats, and which one you get
depends on the endpoint and on how the container was created.

## The formats

| Format | Where it appears | Decoder |
| --- | --- | --- |
| Multiplexed | `logs`, `exec`, `attach` on a container with no TTY | `Stream::Demultiplexer` |
| Raw | the same endpoints when the container has a TTY | `Stream::Raw` |
| JSON lines | `pull`, `push`, `build`, `/events` | `Stream::JSONLines` |

The ergonomic layer picks the right decoder for you. `Container#logs` and
`Container#exec` check whether the container has a TTY, because that is what
decides between the first two.

## Multiplexed framing

Without a TTY, stdout and stderr share one connection and are separated by an
eight-byte header on every frame: a stream id, three bytes of padding, then a
big-endian payload length.

```
+--------+--------+--------+--------+--------+--------+--------+--------+
| stream |   0    |   0    |   0    |          payload length           |
+--------+--------+--------+--------+--------+--------+--------+--------+
```

```ruby
container.exec(%w{make test}) do |stream, chunk|
  case stream
  when :stdout then $stdout << chunk
  when :stderr then $stderr << chunk
  end
end
```

## Why the decoders buffer

HTTP delivers chunks at byte boundaries that have nothing to do with Docker's
framing. A frame header can be split across two chunks; a JSON object can be
split mid-string. Every decoder here accumulates and emits only complete units.

A decoder that assumes a chunk is a message passes its tests — where chunks
happen to align — and interleaves garbage in production. It is worth knowing
this is handled if you are ever tempted to read the raw stream yourself.

## JSON-lines progress

```ruby
client.images.pull("alpine:3.20") do |event|
  puts "#{event["status"]} #{event["progress"]}"
end

client.images.build(context: ".", tag: "app:dev") do |event|
  print event["stream"] if event["stream"]
end
```

Build streams carry the resulting image id in an `aux` object near the end, and
report failures in an `error` key. `Images#build` reads both.

## Endless streams

`system.events` and `logs(follow: true)` do not end on their own. Break out of
the block, or run them on a thread you can stop.

```ruby
client.system.events(filters: { "type" => ["container"] }) do |event|
  break if event["Action"] == "die"
end
```

`read_timeout` applies to the gap between chunks, not to the total duration, so
a quiet stream will not be cut off mid-flow.

## Taking the socket

For genuinely interactive work — sending stdin — `Container#attach` returns the
bidirectional socket itself:

```ruby
io = container.attach(stdin: true, stdout: true, stderr: true)
io.write("echo hello\n")
puts io.readpartial(4096)
io.close
```

This path bypasses `Net::HTTP` deliberately, so the socket comes back with
nothing consumed but the response head.
