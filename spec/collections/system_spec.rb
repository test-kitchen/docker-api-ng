# frozen_string_literal: true

require "spec_helper"

describe Docker::API::System do
  it "reports the daemon's description of itself" do
    client, = faked_client([http_response(200, { "ServerVersion" => "29.7.2", "Name" => "moby" })])
    _(client.system.info["ServerVersion"]).must_equal "29.7.2"
  end

  it "answers ping? without raising when the daemon is unreachable" do
    client = Docker::API::Client.new(url: "unix:///nonexistent-docker.sock", api_version: "1.55")
    _(client.system.ping?).must_equal false
  end

  # Podman implements most of this API and diverges in enough places that
  # callers sometimes need to branch on it.
  it "recognises Podman wearing Docker's API" do
    client, = faked_client([
      http_response(200, { "Components" => [{ "Name" => "Podman Engine" }] }),
    ])
    _(client.system.podman?).must_equal true
  end

  it "reports a plain Docker daemon as not Podman" do
    client, = faked_client([http_response(200, { "Components" => [{ "Name" => "Engine" }] })])
    _(client.system.podman?).must_equal false
  end

  it "decodes the event stream into objects" do
    client, = faked_client([
      http_response(200, %({"Action":"start","Actor":{"Attributes":{"name":"web"}}}\n)),
    ])

    seen = []
    client.system.events { |event| seen << event["Action"] }
    _(seen).must_equal ["start"]
  end

  it "insists on a block for events, which are endless by nature" do
    client, = faked_client([])
    _ { client.system.events }.must_raise ArgumentError
  end
end
