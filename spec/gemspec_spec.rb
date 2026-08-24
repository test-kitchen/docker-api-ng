# frozen_string_literal: true

require "spec_helper"

# What ends up inside the .gem is not what CI exercises: every job here runs
# from a git checkout, where every file is present whether it is packaged or
# not. These assertions are about the artefact a consumer actually installs.
describe "the packaged gem" do
  let(:spec) { Gem::Specification.load("docker-api-ng.gemspec") }

  it "ships every file the library requires at runtime" do
    required = Dir.glob("lib/**/*.rb")

    _(spec.files).must_include "lib/docker/api.rb"
    _(required - spec.files).must_be_empty
  end

  it "ships the RBS signatures, so consumers can type-check against it" do
    _(spec.files).must_include "sig/docker/api/operations.rbs"
  end

  # The Engine API specification is a build-time input to `rake api:generate`,
  # not something an installed copy can do anything with -- the generator that
  # reads it lives in tools/, which is not packaged.
  it "leaves the vendored Engine API specification out" do
    _(spec.files.grep(%r{\Adata/})).must_be_empty
  end

  it "leaves the generator and the test suite out" do
    _(spec.files.grep(%r{\A(tools|spec)/})).must_be_empty
  end

  # A guard rather than a target. The library is roughly 120 KB of Ruby; a
  # figure far above that means something large slipped back into spec.files.
  it "stays small enough that nothing large has crept back in" do
    packaged = spec.files.select { |f| File.file?(f) }.sum { |f| File.size(f) }

    _(packaged).must_be :<, 400_000
  end
end
