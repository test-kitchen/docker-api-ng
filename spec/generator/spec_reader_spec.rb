# frozen_string_literal: true

require "spec_helper"
require "generator/spec_reader"
require "generator/operations_emitter"
require "generator/conformance_emitter"

describe Generator::SpecReader do
  let(:reader) { Generator::SpecReader.new("data/swagger/v#{Docker::API::MAX_API_VERSION}.yaml") }

  it "reads the version the document describes" do
    _(reader.api_version).must_equal Docker::API::MAX_API_VERSION
  end

  it "reads every operation in the document" do
    _(reader.operations.size).must_be :>, 100
  end

  it "converts a NounVerb operationId into a snake_case method name" do
    create = reader.operations.find { |o| o.id == "ContainerCreate" }

    _(create.method_name).must_equal :container_create
    _(create.verb).must_equal :post
    _(create.path).must_equal "/containers/create"
  end

  it "keeps runs of capitals together" do
    parameter = Generator::Parameter.new(name: "someTLSThing", location: :query, type: "string")
    _(parameter.ruby_name).must_equal :some_tls_thing
  end

  # The parameter docker-api silently dropped.
  it "captures every query parameter, including the ones easy to miss by hand" do
    create = reader.operations.find { |o| o.id == "ContainerCreate" }
    _(create.query_params.map(&:name)).must_include "platform"
    _(create.query_params.map(&:name)).must_include "name"
  end

  it "captures path parameters for templated routes" do
    inspected = reader.operations.find { |o| o.id == "ContainerInspect" }

    _(inspected.path_params.map(&:name)).must_equal ["id"]
    _(inspected.path).must_equal "/containers/{id}/json"
  end

  it "records documented error codes so they can be raised meaningfully" do
    inspected = reader.operations.find { |o| o.id == "ContainerInspect" }
    _(inspected.error_codes.keys).must_include 404
  end

  it "records the success code, which is not always 200" do
    _(reader.operations.find { |o| o.id == "ContainerCreate" }.success_codes).must_equal [201]
    _(reader.operations.find { |o| o.id == "ContainerDelete" }.success_codes).must_equal [204]
  end

  # Ruby accepts `def f(until: nil)` as a definition and then refuses to parse
  # any reference to it, because the parser sees the start of a loop.
  it "renames parameters that collide with Ruby keywords" do
    logs = reader.operations.find { |o| o.id == "ContainerLogs" }
    parameter = logs.query_params.find { |p| p.name == "until" }

    _(parameter.ruby_name).must_equal :until_
    _(parameter.renamed?).must_equal true
  end

  it "normalises every body parameter to `body`, whatever the spec calls it" do
    %w{ContainerCreate ExecStart ImageBuild NetworkCreate VolumeCreate}.each do |id|
      operation = reader.operations.find { |o| o.id == id }
      next if operation.body_param.nil?

      _(operation.body_param.ruby_name).must_equal :body
    end
  end

  # The generated files are committed, so an unstable sort would produce a
  # large meaningless diff on every regeneration and hide the real change.
  it "orders operations stably, so regeneration diffs stay readable" do
    _(reader.operations.map(&:id)).must_equal(
      Generator::SpecReader.new("data/swagger/v#{Docker::API::MAX_API_VERSION}.yaml")
        .operations.map(&:id)
    )
  end
end

describe Generator::OperationsEmitter do
  let(:reader) { Generator::SpecReader.new("data/swagger/v#{Docker::API::MAX_API_VERSION}.yaml") }

  # A generator that emits plausible-looking but unparseable Ruby is the
  # failure mode codegen is prone to, and reading the output does not catch it.
  it "emits Ruby that actually parses" do
    source = Generator::OperationsEmitter.new(reader.operations, api_version: "1.55").render
    _(RubyVM::InstructionSequence.compile(source)).wont_be_nil
  end

  it "marks the output as generated, so nobody edits it by hand" do
    source = Generator::OperationsEmitter.new(reader.operations, api_version: "1.55").render
    _(source).must_include "GENERATED -- do not edit"
    _(source).must_include "rake api:generate"
  end

  # The emitter has to know which paths the connection leaves unprefixed, and
  # the two lists drifting apart would make the conformance suite assert the
  # wrong thing.
  it "agrees with the connection about which paths are unversioned" do
    _(Generator::ConformanceEmitter::UNVERSIONED)
      .must_equal Docker::API::Connection::UNVERSIONED
  end

  it "matches the file that is committed" do
    source = Generator::OperationsEmitter.new(reader.operations, api_version: reader.api_version).render
    _(source).must_equal File.read("lib/docker/api/operations.rb")
  end
end

describe "the generated operations layer" do
  it "defines a method for every operation in the specification" do
    reader = Generator::SpecReader.new("data/swagger/v#{Docker::API::MAX_API_VERSION}.yaml")
    missing = reader.operations.map(&:method_name)
      .reject { |name| Docker::API::Operations.method_defined?(name) }

    _(missing).must_be_empty
  end

  it "is plain methods rather than metaprogramming, so it can be read and stepped through" do
    source = File.read("lib/docker/api/operations.rb")
    _(source).wont_include "define_method"
    _(source).wont_include "method_missing"
  end
end
