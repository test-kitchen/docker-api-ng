# frozen_string_literal: true

require "spec_helper"

# The Engine API asks for platforms in two incompatible encodings depending on
# the endpoint. Sending the wrong one fails with "400 failed to parse platform:
# invalid character 'l'", which does not obviously mean "wrong encoding".
describe Docker::API::Platform do
  describe "the OCI object form, wanted by inspect, push, history and save" do
    it "parses os/arch" do
      _(Docker::API::Platform.oci("linux/arm64"))
        .must_equal("os" => "linux", "architecture" => "arm64")
    end

    it "parses os/arch/variant" do
      _(Docker::API::Platform.oci("linux/arm/v7"))
        .must_equal("os" => "linux", "architecture" => "arm", "variant" => "v7")
    end

    it "passes a hash through untouched" do
      given = { "os" => "linux", "architecture" => "s390x" }
      _(Docker::API::Platform.oci(given)).must_equal given
    end

    it "answers nil for nil, so an unset platform stays unset" do
      _(Docker::API::Platform.oci(nil)).must_be_nil
    end
  end

  describe "the string form, wanted by create, build and pull" do
    it "renders a hash" do
      _(Docker::API::Platform.string("os" => "linux", "architecture" => "arm64"))
        .must_equal "linux/arm64"
    end

    it "includes the variant when there is one" do
      _(Docker::API::Platform.string("os" => "linux", "architecture" => "arm", "variant" => "v7"))
        .must_equal "linux/arm/v7"
    end

    it "passes a string through untouched" do
      _(Docker::API::Platform.string("linux/amd64")).must_equal "linux/amd64"
    end

    it "answers nil for nil" do
      _(Docker::API::Platform.string(nil)).must_be_nil
    end
  end
end
