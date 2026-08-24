# frozen_string_literal: true

require_relative "integration_helper"

describe "containers on a real daemon" do
  before do
    client.images.ensure(IntegrationHelper::TEST_IMAGE)
    @container = nil
  end

  after { discard(@container) }

  it "runs through its whole lifecycle" do
    @container = client.containers.create(
      image: IntegrationHelper::TEST_IMAGE, name: unique("lifecycle"),
      cmd: %w{sleep 120}, labels: { "docker-api-ng" => "integration" }
    )

    _(@container.state).must_equal "created"
    _(@container.labels).must_equal("docker-api-ng" => "integration")

    @container.start
    _(@container.running?).must_equal true

    @container.stop(timeout: 1)
    _(@container.running?).must_equal false
  end

  # Without a TTY the daemon multiplexes both streams down one connection with
  # an eight-byte frame header. Getting this wrong interleaves output rather
  # than failing, which is why it is asserted rather than assumed.
  it "keeps stdout and stderr apart when running a command" do
    @container = client.containers.create(
      image: IntegrationHelper::TEST_IMAGE, name: unique("exec"), cmd: %w{sleep 120}
    )
    @container.start

    seen = Hash.new { |hash, key| hash[key] = +"" }
    result = @container.exec(["sh", "-c", "echo out; echo err 1>&2; exit 7"]) do |stream, chunk|
      seen[stream] << chunk
    end

    _(result.stdout.strip).must_equal "out"
    _(result.stderr.strip).must_equal "err"
    _(result.exit_code).must_equal 7
    _(result.success?).must_equal false
    _(seen[:stdout].strip).must_equal "out"
    _(seen[:stderr].strip).must_equal "err"
  end

  it "passes environment into a command" do
    @container = client.containers.create(
      image: IntegrationHelper::TEST_IMAGE, name: unique("env"), cmd: %w{sleep 120}
    )
    @container.start

    result = @container.exec(["sh", "-c", "echo $GREETING"], env: { "GREETING" => "hello" })
    _(result.stdout.strip).must_equal "hello"
  end

  it "reads back what it wrote into the container" do
    @container = client.containers.create(
      image: IntegrationHelper::TEST_IMAGE, name: unique("archive"), cmd: %w{sleep 120}
    )
    @container.start
    @container.archive_in(
      Docker::API::Tar.pack_dockerfile("unused", files: { "note.txt" => "round trip" }).read,
      path: "/tmp"
    )

    _(@container.exec(["cat", "/tmp/note.txt"]).stdout).must_equal "round trip"
  end

  it "collects logs" do
    @container = client.containers.create(
      image: IntegrationHelper::TEST_IMAGE, name: unique("logs"),
      cmd: ["sh", "-c", "echo hello-from-logs"]
    )
    @container.start
    @container.wait

    _(@container.logs).must_include "hello-from-logs"
  end

  it "reports its exit code" do
    @container = client.containers.create(
      image: IntegrationHelper::TEST_IMAGE, name: unique("exit"), cmd: ["sh", "-c", "exit 42"]
    )
    @container.start

    _(@container.wait).must_equal 42
  end

  # A listed container carries its name under "Names" and an inspected one
  # under "Name". Both must answer #name without a second request.
  it "normalises a listed container into the same shape as an inspected one" do
    name = unique("normalise")
    @container = client.containers.create(
      image: IntegrationHelper::TEST_IMAGE, name: name, cmd: %w{sleep 120}
    )

    listed = client.containers.all(all: true).find { |c| c.id == @container.id }
    _(listed.partial?).must_equal true
    _(listed.name).must_equal name
    _(listed.image).must_equal IntegrationHelper::TEST_IMAGE
    _(listed.partial?).must_equal true # still, because nothing needed a reload
  end
end
