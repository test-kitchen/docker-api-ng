# frozen_string_literal: true

require "spec_helper"

describe "container lifecycle" do
  def container(responses, raw: { "Id" => "abc" })
    client, fake = faked_client(responses)
    [Docker::API::Container.new(client: client, raw: raw, partial: false), fake]
  end

  # Docker answers 304 for "already started" and "already stopped". The
  # generated layer raises NotModified for it, which is right there; asking for
  # a state a container is already in is not a failure here.
  describe "a change the daemon reports as already true" do
    it "treats 304 from start as success" do
      subject, = container([http_response(304)])

      _(subject.start).must_be_same_as subject
    end

    it "treats 304 from stop as success" do
      subject, = container([http_response(304)])

      _(subject.stop).must_be_same_as subject
    end

    it "treats 304 from restart as success" do
      subject, = container([http_response(304)])

      _(subject.restart).must_be_same_as subject
    end

    # Rescuing without marking stale left a caller who did handle the
    # exception holding a payload the daemon had already moved past.
    it "still marks the resource stale, so the next read re-fetches" do
      subject, fake = container([
        http_response(304),
        http_response(200, { "Id" => "abc", "State" => { "Status" => "running" } }),
      ])
      subject.start

      _(subject.state).must_equal "running"
      fake.finish
      _(fake.requests.size).must_equal 2
    end

    it "still raises for a status that is a real failure" do
      subject, = container([http_response(409, { "message" => "container is paused" })])

      _ { subject.start }.must_raise Docker::API::Conflict
    end
  end

  # Demultiplexer maps an unrecognised frame id to :unknown. A fixed
  # {stdout:, stderr:} hash turned that into NoMethodError on nil.
  describe "a log stream carrying an unrecognised frame id" do
    it "does not crash the read" do
      frame = [7, 0, 0, 0, 5].pack("CCCCN") + "hello"
      subject, = container(
        [http_response(200, frame, headers: { "Content-Type" => "application/octet-stream" })],
        raw: { "Id" => "abc", "Config" => { "Tty" => false } }
      )

      _(subject.logs).must_be_kind_of String
    end

    it "keeps stdout and stderr separate as before" do
      frames = stream_frame(1, "out") + stream_frame(2, "err")
      subject, = container(
        [http_response(200, frames, headers: { "Content-Type" => "application/octet-stream" })],
        raw: { "Id" => "abc", "Config" => { "Tty" => false } }
      )

      seen = []
      subject.logs { |stream, chunk| seen << [stream, chunk] }
      _(seen).must_equal [[:stdout, "out"], [:stderr, "err"]]
    end
  end

  # "ExitCode": null means the daemon has not reaped the process yet. nil.to_i
  # is 0, so an unknown result used to report success.
  describe "an exec whose exit code the daemon has not reported" do
    def exec_responses(inspect_body)
      [
        http_response(201, { "Id" => "exec-1" }),
        http_response(200, stream_frame(1, "output"),
          headers: { "Content-Type" => "application/octet-stream" }),
        http_response(200, inspect_body),
      ]
    end

    it "does not report success" do
      subject, = container(exec_responses("ExitCode" => nil, "Running" => true))
      result = subject.exec(%w{sleep 1})

      _(result.exit_code).must_be_nil
      _(result.success?).must_equal false
    end

    it "says so rather than claiming a failing exit status" do
      subject, = container(exec_responses("ExitCode" => nil, "Running" => true))
      error = _ { subject.exec(%w{sleep 1}).check! }.must_raise Docker::API::Error

      _(error.message).must_include "no exit code"
    end

    it "still reports a real zero as success" do
      subject, = container(exec_responses("ExitCode" => 0))
      result = subject.exec(%w{true})

      _(result.exit_code).must_equal 0
      _(result.success?).must_equal true
      _(result.check!).must_be_same_as result
    end

    it "still reports a real non-zero as failure" do
      subject, = container(exec_responses("ExitCode" => 127))
      result = subject.exec(%w{nope})

      _(result.exit_code).must_equal 127
      _ { result.check! }.must_raise Docker::API::Error
    end
  end
end
