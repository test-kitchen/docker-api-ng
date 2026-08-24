# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

describe Docker::API::Auth do
  def with_config(contents)
    Dir.mktmpdir do |dir|
      path = File.join(dir, "config.json")
      File.write(path, JSON.generate(contents))
      yield path
    end
  end

  def decode(header)
    JSON.parse(Base64.urlsafe_decode64(header))
  end

  it "decodes a stored auth entry" do
    encoded = Base64.strict_encode64("alice:s3cret")
    with_config("auths" => { Docker::API::Auth::DOCKER_HUB_KEY => { "auth" => encoded } }) do |path|
      credentials = decode(Docker::API::Auth.resolve(nil, config_path: path))

      _(credentials["username"]).must_equal "alice"
      _(credentials["password"]).must_equal "s3cret"
    end
  end

  it "keys Docker Hub under its URL rather than its hostname" do
    _(Docker::API::Auth.registry_key(nil)).must_equal Docker::API::Auth::DOCKER_HUB_KEY
    _(Docker::API::Auth.registry_key("docker.io")).must_equal Docker::API::Auth::DOCKER_HUB_KEY
    _(Docker::API::Auth.registry_key("ghcr.io")).must_equal "ghcr.io"
  end

  it "finds credentials for a private registry by hostname" do
    encoded = Base64.strict_encode64("bob:token")
    with_config("auths" => { "ghcr.io" => { "auth" => encoded } }) do |path|
      credentials = decode(Docker::API::Auth.resolve("ghcr.io", config_path: path))
      _(credentials["username"]).must_equal "bob"
      _(credentials["serveraddress"]).must_equal "ghcr.io"
    end
  end

  # Anonymous pulls of public images must keep working on a machine that has
  # never run `docker login`, so every failure here is soft.
  it "answers nil rather than raising when there is no config file" do
    _(Docker::API::Auth.resolve("ghcr.io", config_path: "/nonexistent/config.json")).must_be_nil
  end

  it "answers nil rather than raising when the config file is malformed" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "config.json")
      File.write(path, "{ not json")
      _(Docker::API::Auth.resolve(nil, config_path: path)).must_be_nil
    end
  end

  it "answers nil when the registry has no entry" do
    with_config("auths" => { "ghcr.io" => { "auth" => "x" } }) do |path|
      _(Docker::API::Auth.resolve("quay.io", config_path: path)).must_be_nil
    end
  end

  it "answers nil when a credential helper is not installed" do
    with_config("credsStore" => "definitely-not-installed") do |path|
      _(Docker::API::Auth.resolve("ghcr.io", config_path: path)).must_be_nil
    end
  end

  it "encodes credentials the way the daemon reads them" do
    header = Docker::API::Auth.encode(username: "u", password: "p", serveraddress: "r")
    _(decode(header)).must_equal("username" => "u", "password" => "p", "serveraddress" => "r")
    _(header).wont_include "\n"
  end

  it "keeps no credentials of its own, so two registries need no coordination" do
    setters = Docker::API::Auth.methods.grep(/=\z/) - Module.methods
    _(setters).must_be_empty
  end
end
