# frozen_string_literal: true

require "spec_helper"
require "generator/operation"
require "generator/conformance_emitter"

describe Generator::ConformanceEmitter do
  let(:operation) do
    Generator::Operation.new(
      id: "ContainerInspect",
      verb: :get,
      path: "/containers/{id}/json",
      parameters: [Generator::Parameter.new(name: "id", location: :path, type: "string", required: true)],
      responses: { 200 => "no error" },
      summary: "Inspect a container",
      tag: "Container"
    )
  end

  let(:source) { Generator::ConformanceEmitter.new([operation], api_version: "1.55").render }

  # The harness calls CGI.unescape. It ran green for a while on spec_helper's
  # transitive load of cgi through mocha, which is the same implicit dependency
  # that let `base64` disappear from under the library without a test noticing.
  it "requires every constant the emitted harness uses" do
    _(source).must_include %(require "cgi")
    _(source).must_include %(require "spec_helper")
  end

  it "emits a suite that parses" do
    _(RubyVM::AbstractSyntaxTree.parse(source)).wont_be_nil
  end

  it "asserts the verb and versioned path of each operation" do
    _(source).must_include "GET /v1.55/containers/sample-id/json"
  end
end
