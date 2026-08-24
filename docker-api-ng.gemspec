# frozen_string_literal: true

require_relative "lib/docker/api/version"

Gem::Specification.new do |spec|
  spec.name          = "docker-api-ng"
  spec.version       = Docker::API::VERSION
  spec.authors       = ["Tim Smith"]
  spec.email         = ["tsmith84@proton.me"]
  spec.summary       = "A Ruby client for the modern Docker Engine API"
  spec.description   = <<~DESC
    A dependency-free Ruby client for the Docker Engine API. The complete API
    surface is generated from Docker's own OpenAPI specification, so keeping up
    with the daemon is a reviewable diff rather than manual archaeology, and an
    ergonomic hand-written layer sits on top of it.
  DESC
  spec.homepage      = "https://github.com/test-kitchen/docker-api-ng"
  spec.license       = "Apache-2.0"

  spec.metadata = {
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "changelog_uri" => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "documentation_uri" => "#{spec.homepage}/blob/main/README.md",
    "source_code_uri" => spec.homepage,
  }

  spec.required_ruby_version = ">= 3.1"

  spec.files = %w{LICENSE NOTICE README.md docker-api-ng.gemspec} +
    Dir.glob("lib/**/*.rb") +
    Dir.glob("sig/**/*.rbs") +
    Dir.glob("data/swagger/*.yaml") +
    Dir.glob("docs/*.md")
  spec.require_paths = ["lib"]

  # No runtime dependencies. Everything this gem needs ships with Ruby.
end
