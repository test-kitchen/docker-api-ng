# frozen_string_literal: true

require "spec_helper"

describe Docker::API::Containers do
  it "lists containers as partial resources" do
    client, = faked_client([http_response(200, [{ "Id" => "a", "Names" => ["/one"] }])])
    containers = client.containers.all(all: true)

    _(containers.size).must_equal 1
    _(containers.first).must_be_kind_of Docker::API::Container
    _(containers.first.partial?).must_equal true
    _(containers.first.name).must_equal "one"
  end

  it "passes list options through to the daemon" do
    client, fake = faked_client([http_response(200, [])])
    client.containers.all(all: true, limit: 3, filters: { "status" => ["running"] })
    fake.finish

    request = CGI.unescape(fake.requests.first)
    _(request).must_include "all=true"
    _(request).must_include "limit=3"
    _(request).must_include 'filters={"status":["running"]}'
  end

  it "inspects by name rather than listing everything and filtering" do
    client, fake = faked_client([http_response(200, { "Id" => "a", "Name" => "/one" })])
    _(client.containers.get("one").name).must_equal "one"
    fake.finish

    _(fake.requests.first).must_include "GET /v1.55/containers/one/json"
  end

  it "raises for a container that is not there" do
    client, = faked_client([http_response(404, { "message" => "No such container: nope" })])
    _ { client.containers.get("nope") }.must_raise Docker::API::NotFound
  end

  # Asking for something by a name a user typed is a question; asking for
  # something you just created is an assertion.
  it "answers nil from #find where #get would raise" do
    client, = faked_client([http_response(404, { "message" => "No such container" })])
    _(client.containers.find("nope")).must_be_nil
  end

  it "converts snake_case attributes into the daemon's spelling" do
    client, fake = faked_client([
      http_response(201, { "Id" => "new" }),
      http_response(200, { "Id" => "new", "Name" => "/worker" }),
    ])
    client.containers.create(
      image: "alpine:3.20", name: "worker", cmd: %w{sleep 30},
      env: ["A=b"], host_config: { "Binds" => ["/a:/b"] }
    )
    fake.finish

    body = fake.requests.first.split("\r\n\r\n").last
    parsed = JSON.parse(body)
    _(parsed["Image"]).must_equal "alpine:3.20"
    _(parsed["Cmd"]).must_equal %w{sleep 30}
    _(parsed["Env"]).must_equal ["A=b"]
    _(parsed["HostConfig"]).must_equal("Binds" => ["/a:/b"])
  end
end
