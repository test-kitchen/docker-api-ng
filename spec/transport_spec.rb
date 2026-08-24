# frozen_string_literal: true

require "spec_helper"

describe Docker::API::Transport do
  describe "choosing a transport for a URL" do
    it "routes each scheme DOCKER_HOST may contain" do
      _(Docker::API::Transport.for(url: "unix:///var/run/docker.sock"))
        .must_be_kind_of Docker::API::Transport::Unix
      _(Docker::API::Transport.for(url: "tcp://192.168.0.5:2375"))
        .must_be_kind_of Docker::API::Transport::Tcp
      _(Docker::API::Transport.for(url: "http://192.168.0.5:2375"))
        .must_be_kind_of Docker::API::Transport::Tcp
      _(Docker::API::Transport.for(url: "npipe:////./pipe/docker_engine"))
        .must_be_kind_of Docker::API::Transport::NamedPipe
    end

    it "treats a bare path as a unix socket, which is what the CLI does" do
      transport = Docker::API::Transport.for(url: "/var/run/docker.sock")
      _(transport).must_be_kind_of Docker::API::Transport::Unix
      _(transport.path).must_equal "/var/run/docker.sock"
    end

    it "keeps the whole socket path, not just part of it" do
      transport = Docker::API::Transport.for(url: "unix:///Users/me/.colima/docker.sock")
      _(transport.path).must_equal "/Users/me/.colima/docker.sock"
    end

    it "upgrades to TLS when TLS material is supplied" do
      transport = Docker::API::Transport.for(url: "tcp://build:2376", tls: { ca_file: "/ca.pem" })
      _(transport).must_be_kind_of Docker::API::Transport::Tls
    end

    it "uses TLS for https regardless of whether material was supplied" do
      _(Docker::API::Transport.for(url: "https://build:2376"))
        .must_be_kind_of Docker::API::Transport::Tls
    end

    it "does not upgrade on an empty TLS hash" do
      _(Docker::API::Transport.for(url: "tcp://build:2375", tls: {}))
        .must_be_kind_of Docker::API::Transport::Tcp
    end

    it "defaults the port by scheme" do
      _(Docker::API::Transport.for(url: "tcp://build").port).must_equal 2375
      _(Docker::API::Transport.for(url: "https://build").port).must_equal 2376
    end

    # `tcp://` with nothing after it is what the Docker CLI resolves to
    # localhost, and a client that fails on it fails on a valid DOCKER_HOST.
    it "reads a bare tcp:// as localhost" do
      transport = Docker::API::Transport.for(url: "tcp://")
      _(transport.host).must_equal "localhost"
      _(transport.port).must_equal 2375
    end

    it "refuses a scheme it cannot honour, naming what it was given" do
      error = _ { Docker::API::Transport.for(url: "ftp://nope") }
        .must_raise Docker::API::ConnectionError
      _(error.message).must_include "ftp"
    end
  end

  describe "failing to connect" do
    # An Errno reaching a caller's rescue clause couples them to our plumbing.
    # docker-api leaks Excon::Error::Socket this way.
    it "raises ConnectionError rather than an Errno, keeping the cause" do
      transport = Docker::API::Transport::Unix.new(path: "/nonexistent/docker.sock")
      error = _ { transport.connect }.must_raise Docker::API::ConnectionError

      _(error).wont_be_kind_of SystemCallError
      _(error.cause).must_be_kind_of SystemCallError
      _(error.message).must_include "/nonexistent/docker.sock"
    end

    it "says where it was trying to reach" do
      transport = Docker::API::Transport::Tcp.new(host: "127.0.0.1", port: 1, open_timeout: 1)
      error = _ { transport.connect }.must_raise Docker::API::ConnectionError
      _(error.message).must_include "127.0.0.1:1"
    end
  end

  describe "describing itself" do
    it "produces a log line that identifies the endpoint" do
      _(Docker::API::Transport::Unix.new(path: "/x.sock").to_s).must_include "/x.sock"
      _(Docker::API::Transport::Tcp.new(host: "h", port: 1).to_s).must_include "host=h"
    end
  end
end
