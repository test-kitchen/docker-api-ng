# frozen_string_literal: true

require "spec_helper"

describe Docker::API::Images do
  it "pulls with the string platform form that /images/create expects" do
    client, fake = faked_client([
      http_response(200, %({"status":"Pulling"}\n)),
      http_response(200, { "Id" => "sha256:x", "RepoTags" => ["alpine:3.20"] }),
    ])
    client.images.pull("alpine:3.20", platform: "linux/arm64")
    fake.finish

    request = CGI.unescape(fake.requests.first)
    _(request).must_include "fromImage=alpine"
    _(request).must_include "tag=3.20"
    _(request).must_include "platform=linux/arm64"
  end

  # Inspect wants a JSON-encoded OCI object where pull wants a string. Sending
  # the string here fails with "400 failed to parse platform".
  it "inspects with the OCI object platform form that /images/{name}/json expects" do
    client, fake = faked_client([http_response(200, { "Id" => "sha256:x" })])
    client.images.get("alpine:3.20", platform: "linux/arm64")
    fake.finish

    _(CGI.unescape(fake.requests.first))
      .must_include 'platform={"os":"linux","architecture":"arm64"}'
  end

  it "yields pull progress as decoded events" do
    client, = faked_client([
      http_response(200, %({"status":"Pulling from library/alpine"}\n{"status":"Download complete"}\n)),
      http_response(200, { "Id" => "sha256:x", "RepoTags" => ["alpine:3.20"] }),
    ])

    events = []
    client.images.pull("alpine:3.20") { |event| events << event["status"] }
    _(events).must_equal ["Pulling from library/alpine", "Download complete"]
  end

  it "reports absence as false rather than raising" do
    client, = faked_client([http_response(404, { "message" => "No such image" })])
    _(client.images.exist?("nope:latest")).must_equal false
  end

  # The daemon reports build failures inside a 200 response rather than as a
  # status code, so a failed build looks like a success to anything that only
  # checks HTTP.
  it "raises when the daemon reports a build failure inside a 200" do
    client, = faked_client([
      http_response(200, %({"stream":"Step 1/1"}\n{"error":"apk add failed"}\n)),
    ])

    error = _ {
      client.images.build(dockerfile: "FROM alpine\nRUN false\n", tag: "x:y")
    }.must_raise Docker::API::Error
    _(error.message).must_include "apk add failed"
  end

  it "sends the build context as a tar archive" do
    client, fake = faked_client([
      http_response(200, %({"stream":"ok"}\n)),
      http_response(200, { "Id" => "sha256:x", "RepoTags" => ["x:y"] }),
    ])
    client.images.build(dockerfile: "FROM alpine\n", tag: "x:y", platform: "linux/arm64")
    fake.finish

    request = fake.requests.first
    _(request).must_include "Content-Type: application/x-tar"
    _(CGI.unescape(request)).must_include "platform=linux/arm64"
    _(CGI.unescape(request)).must_include "t=x:y"
  end
end

describe Docker::API::Image do
  it "splits a reference into repository and tag" do
    _(Docker::API::Image.split_reference("alpine:3.20")).must_equal ["alpine", "3.20"]
    _(Docker::API::Image.split_reference("alpine")).must_equal ["alpine", "latest"]
  end

  # The colon in a registry's port is not a tag separator.
  it "is not fooled by a registry port" do
    _(Docker::API::Image.split_reference("localhost:5000/app"))
      .must_equal ["localhost:5000/app", "latest"]
    _(Docker::API::Image.split_reference("localhost:5000/app:1.0"))
      .must_equal ["localhost:5000/app", "1.0"]
  end

  it "tells a registry hostname from a Docker Hub organisation" do
    _(Docker::API::Image.registry_for("ghcr.io/team/app")).must_equal "ghcr.io"
    _(Docker::API::Image.registry_for("localhost:5000/app")).must_equal "localhost:5000"
    _(Docker::API::Image.registry_for("library/alpine")).must_be_nil
    _(Docker::API::Image.registry_for("alpine")).must_be_nil
  end
end
