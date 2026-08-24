# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "English"

# "No runtime dependencies" is a claim on the README, an assertion in
# spec/regression/docker_api_defects_spec.rb, and -- until this file -- nothing
# that was actually checked.
#
# The gap is that the development bundle is a superset of the release bundle.
# cookstyle pulls in activesupport, activesupport depends on base64, so
# `require "base64"` in lib/ resolved happily in every CI job while failing for
# anyone who installed the gem on its own. A dependency the suite supplies for
# you is a dependency the suite cannot see.
describe "loading with nothing but Ruby" do
  # Everything lib/ is allowed to require. Each of these ships with Ruby as a
  # *default* gem or as core, which is the distinction that matters: bundled
  # gems (base64, csv, logger, ostruct, and the rest of the list that keeps
  # growing) are shipped with Ruby but are NOT on the load path under Bundler
  # unless the application asks for them.
  PERMITTED_REQUIRES = %w{
    English
    digest
    json
    net/http
    openssl
    rbconfig
    rubygems/package
    socket
    stringio
    uri
  }.freeze

  it "requires nothing outside the default gems" do
    found = Dir.glob("lib/**/*.rb").flat_map do |file|
      File.readlines(file).filter_map do |line|
        line[/^\s*require\s+["']([^"']+)["']/, 1]
      end
    end.uniq.sort

    _(found - PERMITTED_REQUIRES).must_equal(
      [],
      "lib/ requires something outside the default gems. A bundled gem here " \
      "fails at require time for anyone whose bundle does not carry it."
    )
  end

  # The allowlist above is only as good as its accuracy, so prove the property
  # directly: load the library in a child process that can see no installed
  # gems at all.
  #
  # Scrubbing the environment matters more than it looks. Bundler exports
  # RUBYOPT, RUBYLIB and BUNDLE_*, and .bundle/config sets BUNDLE_PATH, so a
  # child started from this directory silently inherits vendor/bundle and finds
  # every development dependency -- which is the same superset problem this
  # file exists to close. The child runs from somewhere else with all of it
  # cleared, and reaches lib/ by absolute path.
  it "loads in a process with no gems available" do
    lib = File.expand_path("../lib", __dir__)

    Dir.mktmpdir do |empty|
      env = {
        "GEM_HOME" => empty, "GEM_PATH" => empty,
        "RUBYOPT" => nil, "RUBYLIB" => nil,
        "BUNDLE_GEMFILE" => nil, "BUNDLE_PATH" => nil, "BUNDLE_APP_CONFIG" => empty,
        "BUNDLE_BIN_PATH" => nil
      }
      command = [env, RbConfig.ruby, "-I#{lib}", "-e", 'require "docker/api"; print Docker::API::VERSION']
      output = IO.popen(command, chdir: empty, err: %i{child out}, &:read)

      _($CHILD_STATUS.success?).must_equal(
        true,
        "requiring the library with no gems available failed:\n#{output}"
      )
      _(output).must_equal Docker::API::VERSION
    end
  end
end
