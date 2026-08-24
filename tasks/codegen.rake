# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

require "fileutils"

namespace :api do
  SWAGGER_DIR = "data/swagger"
  DEFAULT_VERSION = "1.55"

  desc "Regenerate the operations layer from the vendored specification"
  task :generate, [:version] do |_task, args|
    version = args[:version] || DEFAULT_VERSION
    $LOAD_PATH.unshift(File.expand_path("../tools", __dir__))

    require "generator/spec_reader"
    require "generator/operations_emitter"
    require "generator/conformance_emitter"
    require "generator/rbs_emitter"

    reader = Generator::SpecReader.new(File.join(SWAGGER_DIR, "v#{version}.yaml"))
    operations = reader.operations

    write("lib/docker/api/operations.rb",
      Generator::OperationsEmitter.new(operations, api_version: reader.api_version).render)
    write("spec/generated/operations_conformance_spec.rb",
      Generator::ConformanceEmitter.new(operations, api_version: reader.api_version).render)
    write("sig/docker/api/operations.rbs",
      Generator::RBSEmitter.new(operations, api_version: reader.api_version).render)

    puts "Generated #{operations.size} operations from Engine API v#{reader.api_version}."
  end

  desc "Fetch a newer Engine API specification and regenerate against it"
  task :sync, [:version] do |_task, args|
    version = args[:version] or abort "usage: rake api:sync[1.56]"
    require "open-uri"

    url = "https://docs.docker.com/reference/api/engine/version/v#{version}.yaml"
    target = File.join(SWAGGER_DIR, "v#{version}.yaml")
    puts "Fetching #{url}"

    FileUtils.mkdir_p(SWAGGER_DIR)
    File.binwrite(target, URI.parse(url).read)

    # The vendored version is referenced in three places that must agree, so
    # they are updated together rather than left for a reviewer to notice.
    bump_constant("lib/docker/api/version.rb", "MAX_API_VERSION", version)
    replace_in("tasks/codegen.rake", /DEFAULT_VERSION = "[\d.]+"/, %{DEFAULT_VERSION = "#{version}"})

    Rake::Task["api:generate"].invoke(version)

    puts "\nReview the diff before committing:"
    sh "git --no-pager diff --stat"
  end

  desc "Fail if the generated files are out of date with the vendored specification"
  task :verify do
    Rake::Task["api:generate"].invoke
    sh "git diff --exit-code -- lib/docker/api/operations.rb " \
       "spec/generated/operations_conformance_spec.rb sig/docker/api/operations.rbs" do |ok, _|
         unless ok
           abort "Generated files are out of date. Run `bundle exec rake api:generate` and commit the result."
         end
       end
  end

  # @param path [String] where to write
  # @param contents [String] what to write
  # @return [void]
  def write(path, contents)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, contents)
    puts "  wrote #{path} (#{contents.lines.size} lines)"
  end

  # @return [void]
  def bump_constant(path, name, value)
    replace_in(path, /#{name} = "[\d.]+"/, %{#{name} = "#{value}"})
  end

  # @return [void]
  def replace_in(path, pattern, replacement)
    contents = File.read(path)
    File.write(path, contents.sub(pattern, replacement))
  end
end
