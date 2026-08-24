# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

describe Docker::API::Tar do
  def entries(io)
    names = {}
    Gem::Package::TarReader.new(io) { |tar| tar.each { |entry| names[entry.full_name] = entry.read } }
    names
  end

  it "packs an in-memory Dockerfile" do
    archive = Docker::API::Tar.pack_dockerfile("FROM alpine\n", files: { "app.rb" => "puts 1" })
    packed = entries(archive)

    _(packed["Dockerfile"]).must_equal "FROM alpine\n"
    _(packed["app.rb"]).must_equal "puts 1"
  end

  it "packs a directory, contents and all" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "Dockerfile"), "FROM alpine\n")
      Dir.mkdir(File.join(dir, "src"))
      File.write(File.join(dir, "src", "main.rb"), "puts 2")

      packed = entries(Docker::API::Tar.pack_directory(dir))
      _(packed.keys).must_include "Dockerfile"
      _(packed["src/main.rb"]).must_equal "puts 2"
    end
  end

  it "honours .dockerignore" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "Dockerfile"), "FROM alpine\n")
      File.write(File.join(dir, "secret.key"), "shh")
      File.write(File.join(dir, ".dockerignore"), "*.key\n")

      packed = entries(Docker::API::Tar.pack_directory(dir))
      _(packed.keys).must_include "Dockerfile"
      _(packed.keys).wont_include "secret.key"
    end
  end

  # Docker's ignore rules let a later "!" pattern re-include something an
  # earlier pattern excluded, so the last matching rule wins.
  it "lets a negation re-include what an earlier pattern excluded" do
    _(Docker::API::Tar.ignored?("keep.key", ["*.key", "!keep.key"])).must_equal false
    _(Docker::API::Tar.ignored?("other.key", ["*.key", "!keep.key"])).must_equal true
  end

  it "excludes everything beneath an ignored directory" do
    _(Docker::API::Tar.ignored?("node_modules/left-pad/index.js", ["node_modules"])).must_equal true
  end

  it "refuses a context that is not a directory" do
    _ { Docker::API::Tar.pack_directory("/nonexistent-context") }.must_raise ArgumentError
  end
end
