# frozen_string_literal: true

require "spec_helper"

# The Engine API returns different shapes for the same object depending on how
# you asked. GET /containers/json says Names: ["/web"]; GET /containers/{id}/json
# says Name: "/web". A client that exposes whichever payload it happened to
# receive pushes that difference onto every caller.
describe Docker::API::Container do
  let(:client) { Docker::API::Client.new(transport: Docker::API::Transport::Fake.new([]), api_version: "1.55") }

  def listed(overrides = {})
    Docker::API::Container.new(
      client: client, partial: true,
      raw: {
        "Id" => "abc123def456", "Names" => ["/dokken-x"], "Image" => "alpine:3.20",
        "State" => "running", "Status" => "Up 2 minutes", "Labels" => { "a" => "b" },
        "Ports" => [{ "PrivatePort" => 80, "PublicPort" => 8080, "Type" => "tcp", "IP" => "0.0.0.0" }],
      }.merge(overrides)
    )
  end

  def inspected(overrides = {})
    Docker::API::Container.new(
      client: client, partial: false,
      raw: {
        "Id" => "abc123def456", "Name" => "/dokken-x",
        "State" => { "Status" => "running", "Running" => true },
        "Config" => { "Image" => "alpine:3.20", "Labels" => { "a" => "b" }, "Tty" => false },
        "NetworkSettings" => {
          "Ports" => { "80/tcp" => [{ "HostIp" => "0.0.0.0", "HostPort" => "8080" }] },
          "Networks" => { "bridge" => { "IPAddress" => "172.17.0.2" } },
        },
      }.merge(overrides)
    )
  end

  describe "normalising the two payload shapes" do
    it "answers #name identically from a list and from an inspect" do
      _(listed.name).must_equal "dokken-x"
      _(inspected.name).must_equal "dokken-x"
    end

    it "answers #state identically, though one is a string and one is a hash" do
      _(listed.state).must_equal "running"
      _(inspected.state).must_equal "running"
      _(listed.running?).must_equal true
      _(inspected.running?).must_equal true
    end

    it "answers #image with the readable name from both" do
      _(listed.image).must_equal "alpine:3.20"
      _(inspected.image).must_equal "alpine:3.20"
    end

    it "answers #labels identically" do
      _(listed.labels).must_equal("a" => "b")
      _(inspected.labels).must_equal("a" => "b")
    end

    it "answers #ports in one shape, though one is an array and one a map" do
      expected = [{ port: 80, protocol: "tcp", host_ip: "0.0.0.0", host_port: 8080 }]
      _(listed.ports).must_equal expected
      _(inspected.ports).must_equal expected
    end
  end

  describe "fetching detail the list did not carry" do
    # A list payload already contains the name under "Names". Reloading to
    # rediscover it would be a wasted round trip on every listed container.
    it "does not reload for something the list already told it" do
      container = listed
      client.operations.expects(:container_inspect).never

      _(container.name).must_equal "dokken-x"
      _(container.image).must_equal "alpine:3.20"
      _(container.state).must_equal "running"
      _(container.partial?).must_equal true
    end

    it "reloads exactly once when an accessor needs inspect-only detail" do
      container = listed
      client.operations.expects(:container_inspect)
        .once.returns(Docker::API::Response.new(status: 200, body: JSON.generate(inspected.raw)))

      2.times { container.tty? }
    end

    it "never reloads a resource that is already complete" do
      container = inspected
      client.operations.expects(:container_inspect).never

      _(container.tty?).must_equal false
      _(container.ip_address).must_equal "172.17.0.2"
    end
  end

  describe "staleness after an action" do
    # Starting a container does not update the payload in hand, so without this
    # a caller who starts a container and asks its state is told "created" --
    # true when it was fetched, and useless now.
    it "refreshes once after an action that changes the daemon's state" do
      container = inspected("State" => { "Status" => "created" })
      _(container.state).must_equal "created"

      client.operations.expects(:container_start).once.returns(nil)
      client.operations.expects(:container_inspect)
        .once.returns(Docker::API::Response.new(status: 200, body: JSON.generate(inspected.raw)))

      container.start
      _(container.stale?).must_equal true
      _(container.state).must_equal "running"
      _(container.state).must_equal "running"
    end
  end

  describe "the untouched payload" do
    it "is always reachable, so nothing modelled here is a ceiling" do
      _(listed.raw["Status"]).must_equal "Up 2 minutes"
      _(listed["Status"]).must_equal "Up 2 minutes"
    end
  end

  describe "identity" do
    it "compares by id, so the same container from two calls is equal" do
      _(listed).must_equal inspected
      _([listed, inspected].uniq.size).must_equal 1
    end
  end
end
