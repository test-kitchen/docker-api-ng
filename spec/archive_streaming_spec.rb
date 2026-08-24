# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

describe "archives are streamed rather than held in memory" do
  def context_dir
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "Dockerfile"), "FROM alpine\n")
      File.write(File.join(dir, "payload.bin"), "x" * 200_000)
      yield dir
    end
  end

  describe "Tar.pack_directory" do
    it "returns a rewound, readable archive" do
      context_dir do |dir|
        archive = Docker::API::Tar.pack_directory(dir)

        begin
          _(archive.pos).must_equal 0
          names = []
          Gem::Package::TarReader.new(archive) { |tar| tar.each { |entry| names << entry.full_name } }
          _(names).must_include "Dockerfile"
          _(names).must_include "payload.bin"
        ensure
          archive.close!
        end
      end
    end

    # The point of the change: the archive lives on disk, so its size is not
    # also charged to the heap on the way to the daemon.
    it "backs the archive with a file rather than a String in memory" do
      context_dir do |dir|
        archive = Docker::API::Tar.pack_directory(dir)

        begin
          _(archive).must_be_kind_of Tempfile
          _(File.size(archive.path)).must_be :>, 200_000
        ensure
          archive.close!
        end
      end
    end
  end

  # Tempfile is a delegator around File, so `is_a?(IO)` is false. The old
  # class-based check in attach_payload would have sent the delegator's to_s.
  describe "a body that is readable but not an IO" do
    it "streams a Tempfile instead of sending its inspect string" do
      context_dir do |dir|
        client, fake = faked_client([
          http_response(200, %({"aux":{"ID":"sha256:abc"}}\n)),
          http_response(200, { "Id" => "sha256:abc", "RepoTags" => ["app:dev"] }),
        ])
        client.images.build(context: dir, tag: "app:dev")
        fake.finish

        request = fake.requests.first
        _(request).must_include "Transfer-Encoding: chunked"
        _(request).wont_include "Tempfile"
        _(request).must_include "Dockerfile"
      end
    end

    it "puts the real archive bytes on the wire" do
      context_dir do |dir|
        client, fake = faked_client([
          http_response(200, %({"aux":{"ID":"sha256:abc"}}\n)),
          http_response(200, { "Id" => "sha256:abc", "RepoTags" => ["app:dev"] }),
        ])
        client.images.build(context: dir, tag: "app:dev")
        fake.finish

        body = fake.requests.first.split("\r\n\r\n", 2).last
        _(body.bytesize).must_be :>, 200_000
      end
    end
  end

  describe "Container#archive_in" do
    it "streams an IO through rather than reading it into a String" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "payload.tar")
        File.binwrite(path, "y" * 150_000)

        client, fake = faked_client([http_response(200, "")])
        container = Docker::API::Container.new(client: client, raw: { "Id" => "abc" })

        File.open(path, "rb") do |io|
          container.archive_in(io, path: "/tmp")
        end
        fake.finish

        request = fake.requests.first
        _(request).must_include "Transfer-Encoding: chunked"
        _(request.split("\r\n\r\n", 2).last.bytesize).must_equal 150_000
      end
    end

    it "still accepts a plain String body" do
      client, fake = faked_client([http_response(200, "")])
      container = Docker::API::Container.new(client: client, raw: { "Id" => "abc" })
      container.archive_in("raw tar bytes", path: "/tmp")
      fake.finish

      _(fake.requests.first).must_include "raw tar bytes"
    end
  end
end

describe "a TLS handshake that fails" do
  # An SSLSocket only closes the socket underneath it once sync_close is set
  # and the handshake has produced an object that owns it. Anything raising
  # before that used to leave the descriptor open until GC.
  it "closes the socket it opened" do
    server = TCPServer.new("127.0.0.1", 0)
    opened = []

    transport = Docker::API::Transport::Tls.new(host: "127.0.0.1", port: server.addr[1])
    transport.define_singleton_method(:super_socket) do
      socket = Socket.tcp("127.0.0.1", server.addr[1])
      opened << socket
      socket
    end

    begin
      # The server never speaks TLS, so the handshake cannot complete.
      Thread.new { server.accept.close rescue nil }
      _ { transport.connect }.must_raise Docker::API::ConnectionError

      _(opened.size).must_equal 1
      _(opened.first.closed?).must_equal true
    ensure
      opened.each { |s| s.close unless s.closed? }
      server.close
    end
  end
end
