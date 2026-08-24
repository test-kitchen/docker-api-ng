# frozen_string_literal: true

require "spec_helper"

# HTTP hands us chunks at byte boundaries that have nothing to do with Docker's
# framing. A decoder that assumes a chunk is a message passes its tests and
# then interleaves garbage in production.
describe Docker::API::Stream::Demultiplexer do
  it "separates stdout from stderr" do
    seen = []
    demux = Docker::API::Stream::Demultiplexer.new { |name, chunk| seen << [name, chunk] }
    demux << stream_frame(1, "out") << stream_frame(2, "err")

    _(seen).must_equal [[:stdout, "out"], [:stderr, "err"]]
  end

  it "reassembles a frame split across chunk boundaries" do
    seen = []
    demux = Docker::API::Stream::Demultiplexer.new { |name, chunk| seen << [name, chunk] }
    stream_frame(1, "hello world").each_byte.each_slice(3) { |slice| demux << slice.pack("C*") }

    _(seen).must_equal [[:stdout, "hello world"]]
  end

  it "emits nothing until a frame is complete" do
    seen = []
    demux = Docker::API::Stream::Demultiplexer.new { |name, chunk| seen << [name, chunk] }
    demux << stream_frame(1, "partial").byteslice(0, 10)

    _(seen).must_be_empty
    _(demux.pending?).must_equal true
  end

  it "handles several frames arriving in one chunk" do
    seen = []
    demux = Docker::API::Stream::Demultiplexer.new { |name, chunk| seen << [name, chunk] }
    demux << (stream_frame(1, "a") + stream_frame(2, "b") + stream_frame(1, "c"))

    _(seen).must_equal [[:stdout, "a"], [:stderr, "b"], [:stdout, "c"]]
  end

  it "yields text as UTF-8, not as the binary it arrived as" do
    seen = []
    demux = Docker::API::Stream::Demultiplexer.new { |_name, chunk| seen << chunk }
    demux << stream_frame(1, "héllo")

    _(seen.first.encoding).must_equal Encoding::UTF_8
    _(seen.first).must_equal "héllo"
  end

  it "refuses to be built without somewhere to send frames" do
    _ { Docker::API::Stream::Demultiplexer.new }.must_raise ArgumentError
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

  it "holds back a trailing partial line" do
    seen = []
    lines = Docker::API::Stream::JSONLines.new { |object| seen << object }
    lines << %({"a":1}\n{"a":)

    _(seen.size).must_equal 1
  end

  it "ignores blank lines rather than choking on them" do
    seen = []
    lines = Docker::API::Stream::JSONLines.new { |object| seen << object }
    lines << %({"a":1}\n\n\n{"a":2}\n)

    _(seen.size).must_equal 2
  end

  it "raises a gem error, not a JSON error, on malformed input" do
    lines = Docker::API::Stream::JSONLines.new { |_| }
    error = _ { lines << "not json at all\n" }.must_raise Docker::API::StreamError
    _(error).wont_be_kind_of JSON::ParserError
  end
end

describe Docker::API::Stream::Raw do
  it "passes bytes straight through" do
    seen = []
    raw = Docker::API::Stream::Raw.new { |chunk| seen << chunk }
    raw << "a" << "b"

    _(seen).must_equal %w{a b}
  end
end
