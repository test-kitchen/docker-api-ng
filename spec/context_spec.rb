# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"
require "digest"

# `docker context use colima` exports nothing. It writes currentContext into
# ~/.docker/config.json, and every later docker command resolves the endpoint
# from the store -- so a client reading only DOCKER_HOST disagrees with the CLI
# on the same machine and falls back to /var/run/docker.sock, which Colima,
# Rancher Desktop, rootless Docker and Podman generally do not create.
describe Docker::API::Context do
  def store(contexts, current: nil, config_extra: {})
    Dir.mktmpdir do |root|
      contexts.each do |name, endpoint|
        digest = Digest::SHA256.hexdigest(name)
        dir = File.join(root, "contexts", "meta", digest)
        FileUtils.mkdir_p(dir)
        File.write(File.join(dir, "meta.json"), JSON.generate(
          "Name" => name,
          "Endpoints" => { "docker" => endpoint }
        ))
      end
      File.write(File.join(root, "config.json"),
        JSON.generate({ "currentContext" => current }.compact.merge(config_extra)))
      yield root
    end
  end

  it "resolves the endpoint of the context config.json names" do
    store({ "colima" => { "Host" => "unix:///Users/x/.colima/docker.sock" } }, current: "colima") do |root|
      _(Docker::API::Context.resolve({}, root: root))
        .must_equal(url: "unix:///Users/x/.colima/docker.sock")
    end
  end

  it "prefers DOCKER_CONTEXT over currentContext, as the CLI does" do
    contexts = {
      "colima" => { "Host" => "unix:///colima.sock" },
      "remote" => { "Host" => "tcp://build.internal:2376" },
    }
    store(contexts, current: "colima") do |root|
      _(Docker::API::Context.resolve({ "DOCKER_CONTEXT" => "remote" }, root: root))
        .must_equal(url: "tcp://build.internal:2376")
    end
  end

  # "default" is not in the store: it means DOCKER_HOST or the platform socket.
  it "answers nil for the default context" do
    store({}, current: "default") do |root|
      _(Docker::API::Context.resolve({}, root: root)).must_be_nil
    end
  end

  it "answers nil when no context is set" do
    store({}) do |root|
      _(Docker::API::Context.resolve({}, root: root)).must_be_nil
    end
  end

  # Every failure is soft: falling back to the platform default is what the
  # CLI does and beats refusing to start.
  it "answers nil when the named context is not in the store" do
    store({}, current: "deleted-yesterday") do |root|
      _(Docker::API::Context.resolve({}, root: root)).must_be_nil
    end
  end

  it "answers nil for a malformed meta.json rather than raising" do
    Dir.mktmpdir do |root|
      digest = Digest::SHA256.hexdigest("broken")
      FileUtils.mkdir_p(File.join(root, "contexts", "meta", digest))
      File.write(File.join(root, "contexts", "meta", digest, "meta.json"), "{ not json")
      File.write(File.join(root, "config.json"), JSON.generate("currentContext" => "broken"))

      _(Docker::API::Context.resolve({}, root: root)).must_be_nil
    end
  end

  it "answers nil when there is no store at all" do
    _(Docker::API::Context.resolve({}, root: "/nonexistent/.docker")).must_be_nil
  end

  it "picks up TLS material a context carries" do
    store({ "secured" => { "Host" => "tcp://build:2376" } }, current: "secured") do |root|
      digest = Digest::SHA256.hexdigest("secured")
      tls_dir = File.join(root, "contexts", "tls", digest, "docker")
      FileUtils.mkdir_p(tls_dir)
      %w{ca.pem cert.pem key.pem}.each { |f| File.write(File.join(tls_dir, f), "material") }

      resolved = Docker::API::Context.resolve({}, root: root)
      _(resolved[:url]).must_equal "tcp://build:2376"
      _(resolved[:tls][:ca_file]).must_equal File.join(tls_dir, "ca.pem")
      _(resolved[:tls][:verify]).must_equal true
    end
  end
end

describe "Config resolution order" do
  def with_context(host)
    Dir.mktmpdir do |root|
      digest = Digest::SHA256.hexdigest("ctx")
      FileUtils.mkdir_p(File.join(root, "contexts", "meta", digest))
      File.write(File.join(root, "contexts", "meta", digest, "meta.json"),
        JSON.generate("Name" => "ctx", "Endpoints" => { "docker" => { "Host" => host } }))
      File.write(File.join(root, "config.json"), JSON.generate("currentContext" => "ctx"))
      yield root
    end
  end

  it "uses the context when DOCKER_HOST is not set" do
    with_context("unix:///ctx.sock") do |root|
      _(Docker::API::Config.from_env({ "DOCKER_CONFIG" => root }).url).must_equal "unix:///ctx.sock"
    end
  end

  # The property that keeps this from changing anything for existing callers.
  it "lets DOCKER_HOST win over the context" do
    with_context("unix:///ctx.sock") do |root|
      config = Docker::API::Config.from_env({ "DOCKER_CONFIG" => root, "DOCKER_HOST" => "tcp://env:2375" })

      _(config.url).must_equal "tcp://env:2375"
    end
  end

  it "lets an explicit url: win over both" do
    with_context("unix:///ctx.sock") do |root|
      config = Docker::API::Config.from_env(
        { "DOCKER_CONFIG" => root, "DOCKER_HOST" => "tcp://env:2375" }, url: "tcp://explicit:2375"
      )

      _(config.url).must_equal "tcp://explicit:2375"
    end
  end

  it "falls back to the platform default when no context applies" do
    Dir.mktmpdir do |root|
      _(Docker::API::Config.from_env({ "DOCKER_CONFIG" => root }).url)
        .must_equal Docker::API::Config.default_url
    end
  end

  it "treats an empty DOCKER_HOST as unset, so the context still applies" do
    with_context("unix:///ctx.sock") do |root|
      _(Docker::API::Config.from_env({ "DOCKER_CONFIG" => root, "DOCKER_HOST" => "" }).url)
        .must_equal "unix:///ctx.sock"
    end
  end
end

describe "build's overloaded dockerfile: argument" do
  # With no context:, dockerfile: is contents. With a context:, it is a
  # filename inside it. Passing both sent the whole Dockerfile source as the
  # `dockerfile=` query parameter and let the daemon report a missing file.
  it "refuses Dockerfile contents alongside a directory context" do
    Dir.mktmpdir do |dir|
      client, = faked_client([])
      error = _ {
        client.images.build(context: dir, dockerfile: "FROM alpine\nRUN apk add curl\n")
      }.must_raise ArgumentError

      _(error.message).must_include "names a file inside context:"
    end
  end

  it "still accepts a filename alongside a directory context" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "Dockerfile.dev"), "FROM alpine\n")
      client, fake = faked_client([
        http_response(200, %({"aux":{"ID":"sha256:abc"}}\n)),
        http_response(200, { "Id" => "sha256:abc" }),
      ])
      client.images.build(context: dir, dockerfile: "Dockerfile.dev")
      fake.finish

      _(CGI.unescape(fake.requests.first)).must_include "dockerfile=Dockerfile.dev"
    end
  end

  it "still accepts contents when there is no context" do
    client, fake = faked_client([
      http_response(200, %({"aux":{"ID":"sha256:abc"}}\n)),
      http_response(200, { "Id" => "sha256:abc" }),
    ])
    client.images.build(dockerfile: "FROM alpine\nRUN apk add curl\n")
    fake.finish

    _(CGI.unescape(fake.requests.first)).must_include "dockerfile=Dockerfile"
  end
end
