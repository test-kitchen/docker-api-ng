# frozen_string_literal: true

require "spec_helper"

describe Docker::API::Path do
  # Image references are `registry/team/image:tag`, and the daemon's router
  # matches those slashes as path structure. Percent-encoding them turns a
  # valid reference into a 404.
  it "leaves slashes and colons alone, so image references survive" do
    _(Docker::API::Path.escape("registry.example.com/team/app:2026.08"))
      .must_equal "registry.example.com/team/app:2026.08"
  end

  it "escapes characters that would genuinely break a path" do
    _(Docker::API::Path.escape("weird name")).must_equal "weird%20name"
    _(Docker::API::Path.escape("a#b")).must_equal "a%23b"
    _(Docker::API::Path.escape("a?b")).must_equal "a%3Fb"
    _(Docker::API::Path.escape("100%")).must_equal "100%25"
  end

  it "leaves ordinary ids untouched" do
    _(Docker::API::Path.escape("3f2a9c1b0e4d")).must_equal "3f2a9c1b0e4d"
  end
end
