# frozen_string_literal: true

require "spec_helper"

describe "image reference parsing" do
  Split = Docker::API::Image

  describe ".split_reference" do
    it "defaults a bare repository to latest" do
      _(Split.split_reference("alpine")).must_equal ["alpine", "latest"]
    end

    it "separates an ordinary tag" do
      _(Split.split_reference("alpine:3.20")).must_equal ["alpine", "3.20"]
      _(Split.split_reference("registry.io/team/app:1.0")).must_equal ["registry.io/team/app", "1.0"]
    end

    # The colon in a registry port is not a tag separator.
    it "does not mistake a registry port for a tag" do
      _(Split.split_reference("localhost:5000/app")).must_equal ["localhost:5000/app", "latest"]
      _(Split.split_reference("localhost:5000/app:1.0")).must_equal ["localhost:5000/app", "1.0"]
    end

    # ...and neither is the colon inside a digest. This is the form every
    # lockfile, Renovate pin and reproducible build uses.
    it "keeps a digest whole" do
      _(Split.split_reference("alpine@sha256:1a2b3c")).must_equal ["alpine", "sha256:1a2b3c"]
    end

    it "keeps a digest whole on a registry-qualified reference with a port" do
      _(Split.split_reference("registry.io:5000/team/app@sha256:1a2b3c"))
        .must_equal ["registry.io:5000/team/app", "sha256:1a2b3c"]
    end
  end

  describe ".join_reference" do
    it "joins a tag with a colon and a digest with an at sign" do
      _(Split.join_reference("alpine", "3.20")).must_equal "alpine:3.20"
      _(Split.join_reference("alpine", "sha256:1a2b")).must_equal "alpine@sha256:1a2b"
    end

    # Stated outright rather than derived: an untagged reference gains
    # ":latest" on the way back, which no rule about colons expresses -- and
    # "localhost:5000/app" is precisely the case where guessing from the
    # presence of a colon gets it wrong.
    it "round-trips everything split_reference produces" do
      {
        "alpine" => "alpine:latest",
        "alpine:3.20" => "alpine:3.20",
        "localhost:5000/app" => "localhost:5000/app:latest",
        "localhost:5000/app:1.0" => "localhost:5000/app:1.0",
        "registry.io/team/app:1.0" => "registry.io/team/app:1.0",
        "alpine@sha256:1a2b3c" => "alpine@sha256:1a2b3c",
        "registry.io:5000/team/app@sha256:1a2b3c" => "registry.io:5000/team/app@sha256:1a2b3c",
      }.each do |reference, expected|
        repo, tag = Split.split_reference(reference)

        _(Split.join_reference(repo, tag)).must_equal expected
      end
    end
  end

  # auth: is passed explicitly throughout. Without it, pull calls
  # Auth.resolve, which reads the real ~/.docker/config.json and shells out to
  # the developer's credential helper -- so a unit test would put a live
  # registry token on the wire and into any failure diff.
  describe "pulling by digest" do
    it "sends the repository and the digest the daemon expects" do
      client, fake = faked_client([
        http_response(200, %({"status":"Pulling"}\n)),
        http_response(200, { "Id" => "sha256:1a2b3c", "RepoTags" => [] }),
      ])
      client.images.pull("alpine@sha256:1a2b3c", auth: "stub-token")
      fake.finish

      pull = CGI.unescape(fake.requests.first)
      _(pull).must_include "fromImage=alpine"
      _(pull).must_include "tag=sha256:1a2b3c"
      _(pull).wont_include "fromImage=alpine@sha256"
    end

    it "inspects the digest reference it just pulled, not a colon-joined one" do
      client, fake = faked_client([
        http_response(200, %({"status":"Pulling"}\n)),
        http_response(200, { "Id" => "sha256:1a2b3c", "RepoTags" => [] }),
      ])
      client.images.pull("alpine@sha256:1a2b3c", auth: "stub-token")
      fake.finish

      _(CGI.unescape(fake.requests[1])).must_include "/images/alpine@sha256:1a2b3c/json"
    end
  end
end

describe "pushing an image" do
  def image(raw)
    client, fake = faked_client([http_response(200, %({"status":"Pushed"}\n))])
    [Docker::API::Image.new(client: client, raw: raw, partial: false), fake]
  end

  # The daemon pushes every tag under a repository when it is given no tag at
  # all, so an image tagged twice used to publish both.
  it "pushes the tag it stands for rather than the whole repository" do
    subject, fake = image("Id" => "sha256:x", "RepoTags" => ["registry.io/team/app:1.0",
                                                            "registry.io/team/app:latest"])
    subject.push(auth: "token")
    fake.finish

    request = CGI.unescape(fake.requests.first)
    _(request).must_include "/images/registry.io/team/app/push"
    _(request).must_include "tag=1.0"
  end

  it "still lets a caller name a different tag" do
    subject, fake = image("Id" => "sha256:x", "RepoTags" => ["registry.io/team/app:1.0"])
    subject.push(tag: "stable", auth: "token")
    fake.finish

    _(CGI.unescape(fake.requests.first)).must_include "tag=stable"
  end

  # Falling back to the id produced a push against the repository "sha256",
  # because splitting "sha256:1a2b..." on the last colon looks like a tag.
  it "refuses an untagged image instead of inventing a repository from its id" do
    subject, = image("Id" => "sha256:1a2b3c4d5e6f", "RepoTags" => [])

    error = _ { subject.push(auth: "token") }.must_raise Docker::API::Error
    _(error.message).must_include "has no repository tag"
    _(error.operation).must_equal "image_push"
  end

  it "treats <none>:<none> as untagged" do
    subject, = image("Id" => "sha256:1a2b3c4d5e6f", "RepoTags" => ["<none>:<none>"])

    _ { subject.push(auth: "token") }.must_raise Docker::API::Error
  end
end
