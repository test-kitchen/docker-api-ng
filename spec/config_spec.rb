# frozen_string_literal: true

require "spec_helper"

describe Docker::API::Config do
  it "reads the daemon URL from DOCKER_HOST" do
    config = Docker::API::Config.from_env({ "DOCKER_HOST" => "tcp://build:2375" })
    _(config.url).must_equal "tcp://build:2375"
  end

  it "falls back to the platform default when the environment says nothing" do
    config = Docker::API::Config.from_env({})
    _(config.url).must_equal Docker::API::Config.default_url
  end

  it "builds TLS material from DOCKER_CERT_PATH, as the CLI does" do
    config = Docker::API::Config.from_env({
      "DOCKER_HOST" => "tcp://build:2376",
      "DOCKER_CERT_PATH" => "/certs",
      "DOCKER_TLS_VERIFY" => "1",
    })

    _(config.tls[:ca_file]).must_equal "/certs/ca.pem"
    _(config.tls[:cert_file]).must_equal "/certs/cert.pem"
    _(config.tls[:key_file]).must_equal "/certs/key.pem"
    _(config.tls[:verify]).must_equal true
  end

  # DOCKER_TLS_VERIFY is a presence flag, not a boolean: the CLI treats an
  # exported-but-empty value as off.
  it "treats an empty DOCKER_TLS_VERIFY as off" do
    config = Docker::API::Config.from_env({
      "DOCKER_CERT_PATH" => "/certs", "DOCKER_TLS_VERIFY" => "",
    })
    _(config.tls[:verify]).must_equal false
  end

  it "reports no TLS material when DOCKER_CERT_PATH is unset" do
    _(Docker::API::Config.from_env({}).tls).must_be_empty
  end

  it "lets explicit arguments beat the environment" do
    config = Docker::API::Config.from_env(
      { "DOCKER_HOST" => "tcp://from-env:2375" }, url: "unix:///explicit.sock"
    )
    _(config.url).must_equal "unix:///explicit.sock"
  end

  # docker-api exposes Docker.url= and Docker.creds= as process-global setters,
  # so a second caller silently inherits or clobbers the first caller's daemon.
  it "is frozen, so nothing can reach in and change a live client's daemon" do
    config = Docker::API::Config.from_env({})
    _(config).must_be :frozen?
    _(config.tls).must_be :frozen?
  end

  it "says so loudly when the environment is passed as options by mistake" do
    error = _ {
      Docker::API::Config.from_env("DOCKER_HOST" => "tcp://build:2375")
    }.must_raise ArgumentError
    _(error.message).must_include "DOCKER_HOST"
  end

  it "exposes no setters at all" do
    setters = Docker::API::Config.instance_methods.grep(/=\z/) - Object.instance_methods
    _(setters).must_be_empty
  end
end
