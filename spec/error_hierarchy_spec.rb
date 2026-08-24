# frozen_string_literal: true

require "spec_helper"

# The README's promise: "Everything this gem raises descends from
# Docker::API::Error, and nothing from beneath the abstraction escapes." A nil
# from an empty body indexed one line later is not beneath the abstraction --
# it is this gem's own NoMethodError, which is worse.
describe "an empty body where a document was required" do
  describe "Response#json!" do
    it "answers the parsed document when there is one" do
      response = Docker::API::Response.new(status: 200, body: '{"Id":"abc"}')

      _(response.json!).must_equal("Id" => "abc")
    end

    it "raises a StreamError naming the status when the body is empty" do
      response = Docker::API::Response.new(status: 201, body: "")
      error = _ { response.json! }.must_raise Docker::API::StreamError

      _(error.message).must_include "HTTP 201"
      _(error.message).must_include "empty body"
      _(error.status).must_equal 201
    end

    # #json keeps answering nil: 204 and 304 legitimately carry nothing, and
    # callers that do not index the result rely on that.
    it "leaves #json answering nil, which is correct for a 204" do
      _(Docker::API::Response.new(status: 204, body: "").json).must_be_nil
    end
  end

  describe "the call sites that index a response" do
    it "raises a Docker::API::Error from create rather than NoMethodError" do
      client, = faked_client([http_response(201, "")])

      _ { client.containers.create(image: "alpine") }.must_raise Docker::API::StreamError
    end

    it "raises a Docker::API::Error from wait rather than NoMethodError" do
      client, = faked_client([http_response(200, "")])
      container = Docker::API::Container.new(client: client, raw: { "Id" => "abc" })

      _ { container.wait }.must_raise Docker::API::StreamError
    end

    it "raises a Docker::API::Error from a list rather than NoMethodError" do
      client, = faked_client([http_response(200, "")])

      _ { client.containers.all }.must_raise Docker::API::StreamError
    end

    it "raises a Docker::API::Error from network create rather than NoMethodError" do
      client, = faked_client([http_response(201, "")])

      _ { client.networks.create("dokken") }.must_raise Docker::API::StreamError
    end

    # The property that matters, stated once: whatever goes wrong, a consumer
    # rescuing Docker::API::Error catches it.
    it "keeps every one of them inside the hierarchy" do
      [
        -> { faked_client([http_response(201, "")]).first.containers.create(image: "alpine") },
        -> { faked_client([http_response(200, "")]).first.containers.all },
        -> { faked_client([http_response(200, "")]).first.volumes.all },
        -> { faked_client([http_response(200, "")]).first.images.all },
      ].each do |call|
        error = _(&call).must_raise Docker::API::Error

        _(error).wont_be_kind_of NoMethodError
      end
    end
  end
end

# The daemon reports an image id through an aux event that BuildKit does not
# always emit, so an untagged build could finish with nothing to look up.
describe "a build that produced nothing to look up" do
  it "says so instead of requesting GET /images//json" do
    client, fake = faked_client([http_response(200, %({"stream":"Step 1/1 : FROM alpine\\n"}\n))])
    error = _ { client.images.build(dockerfile: "FROM alpine\n") }.must_raise Docker::API::Error

    _(error.message).must_include "no tag: was given"
    _(error.operation).must_equal "image_build"
    fake.finish
    _(fake.requests.size).must_equal 1
  end

  it "still inspects by tag when one was given" do
    client, fake = faked_client([
      http_response(200, %({"stream":"Step 1/1"}\n)),
      http_response(200, { "Id" => "sha256:x", "RepoTags" => ["app:dev"] }),
    ])
    client.images.build(dockerfile: "FROM alpine\n", tag: "app:dev")
    fake.finish

    _(fake.requests[1]).must_include "/images/app:dev/json"
  end

  it "still inspects by aux id when the daemon reported one" do
    client, fake = faked_client([
      http_response(200, %({"aux":{"ID":"sha256:abc"}}\n)),
      http_response(200, { "Id" => "sha256:abc" }),
    ])
    client.images.build(dockerfile: "FROM alpine\n")
    fake.finish

    _(fake.requests[1]).must_include "/images/sha256:abc/json"
  end
end
