# frozen_string_literal: true

require_relative "integration_helper"

describe "a real Docker daemon" do
  it "negotiates a version both sides understand" do
    version = client.api_version

    _(Gem::Version.new(version)).must_be :>=, Gem::Version.new(Docker::API::MIN_API_VERSION)
    _(Gem::Version.new(version)).must_be :<=, Gem::Version.new(Docker::API::MAX_API_VERSION)
  end

  it "answers a ping" do
    _(client.system.ping?).must_equal true
  end

  it "describes itself" do
    _(client.system.info["ServerVersion"]).wont_be_nil
    _(client.system.version["ApiVersion"]).wont_be_nil
  end

  it "reports an unknown container as missing rather than failing oddly" do
    _ { client.containers.get("#{IntegrationHelper::PREFIX}-does-not-exist") }
      .must_raise Docker::API::NotFound
  end

  it "reaches an endpoint that has no ergonomic wrapper" do
    _(client.operations.system_data_usage.status).must_equal 200
  end
end
