# frozen_string_literal: true

require "spec_helper"

describe "Docker::API version constants" do
  it "exposes a semver gem version" do
    _(Docker::API::VERSION).must_match(/\A\d+\.\d+\.\d+/)
  end

  it "supports a range of Engine API versions" do
    _(Gem::Version.new(Docker::API::MIN_API_VERSION))
      .must_be :<, Gem::Version.new(Docker::API::MAX_API_VERSION)
  end

  it "vendors a specification for the version it claims to support" do
    _(File).must_be :exist?, "data/swagger/v#{Docker::API::MAX_API_VERSION}.yaml"
  end
end
