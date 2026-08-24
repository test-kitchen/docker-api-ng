# frozen_string_literal: true

require "spec_helper"

describe Docker::API::Networks do
  it "creates a network from readable options" do
    client, fake = faked_client([
      http_response(201, { "Id" => "netid" }),
      http_response(200, { "Id" => "netid", "Name" => "dokken", "EnableIPv6" => true }),
    ])
    network = client.networks.create("dokken", driver: "bridge", ipv6: true)
    fake.finish

    body = JSON.parse(fake.requests.first.split("\r\n\r\n").last)
    _(body["Name"]).must_equal "dokken"
    _(body["Driver"]).must_equal "bridge"
    _(body["EnableIPv6"]).must_equal true
    _(network.ipv6?).must_equal true
  end

  # Two processes racing to create the same shared network is ordinary rather
  # than exceptional; parallel test suites do it constantly.
  it "treats losing a creation race as success" do
    client, = faked_client([
      http_response(404, { "message" => "network dokken not found" }),
      http_response(409, { "message" => "network with name dokken already exists" }),
      http_response(200, { "Id" => "netid", "Name" => "dokken" }),
    ])

    _(client.networks.ensure("dokken").name).must_equal "dokken"
  end

  it "returns the existing network without creating anything" do
    client, fake = faked_client([http_response(200, { "Id" => "netid", "Name" => "dokken" })])
    _(client.networks.ensure("dokken").name).must_equal "dokken"
    fake.finish

    _(fake.requests.size).must_equal 1
  end

  it "connects a container with aliases" do
    client, fake = faked_client([
      http_response(200, { "Id" => "netid", "Name" => "dokken" }),
      http_response(200, nil),
    ])
    client.networks.get("dokken").connect("abc123", aliases: %w{web web.local})
    fake.finish

    body = JSON.parse(fake.requests.last.split("\r\n\r\n").last)
    _(body["Container"]).must_equal "abc123"
    _(body["EndpointConfig"]["Aliases"]).must_equal %w{web web.local}
  end

  it "accepts a container resource as readily as an id" do
    client, fake = faked_client([
      http_response(200, { "Id" => "netid", "Name" => "dokken" }),
      http_response(200, nil),
    ])
    container = Docker::API::Container.new(client: client, raw: { "Id" => "abc123" })
    client.networks.get("dokken").connect(container)
    fake.finish

    _(JSON.parse(fake.requests.last.split("\r\n\r\n").last)["Container"]).must_equal "abc123"
  end
end
