# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0
#
# Unit-test bootstrap.
#
# Everything outside spec/integration is hermetic: no Docker daemon, no
# network, no reads of the real home directory, and no sleeping. The one place
# a real socket appears is Transport::Fake, which uses a socket pair precisely
# so that hermetic tests still exercise real socket semantics.

if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start do
    add_filter "/spec/"
    add_filter "/tools/"
    # Generated code is verified by its own conformance suite rather than by
    # line coverage, which would only measure how many endpoints a test happens
    # to call.
    add_filter "lib/docker/api/operations.rb"
    enable_coverage :branch
  end
end

# Specs read request bytes back through CGI.unescape. Required here rather than
# left to a transitive load: cgi was arriving via mocha, which nothing declared
# and which mocha 3 stopped doing -- turning a routine dependency bump into 115
# "uninitialized constant CGI" errors across five spec files.
#
# The generated conformance suite emits its own require for the same reason.
require "cgi"

require "minitest/autorun"
require "mocha/minitest"

# Refuse to stub a method that does not exist on the object being stubbed.
#
# Without this, a spec can stub a typo, assert happily against its own mistake,
# and stay green while the real call fails for every user. Note the value:
# mocha treats an unrecognised setting as :allow, so :prohibit or :strict would
# look configured and enforce nothing.
Mocha.configure do |c|
  c.stubbing_non_existent_method = :prevent
end

# Make "no reads of the real home directory" true rather than aspirational.
#
# Auth.resolve falls back to Dir.home when no config_path is given, and
# Images#pull calls it on every pull with no auth: argument. On a machine that
# has run `docker login` -- every developer's, and any CI runner with a
# registry configured -- that reads the real ~/.docker/config.json, shells out
# to the configured credential helper, and puts a live registry token into the
# request bytes. Transport::Fake records those bytes, and minitest prints them
# on failure, so a routine assertion diff can publish a working credential to a
# terminal or a CI log.
#
# Dir.home reads HOME, or USERPROFILE on Windows. Pointing both somewhere empty
# for the duration of the suite makes the fallback find nothing, which is what
# every unit test here already assumes it does.
require "tmpdir"
require "fileutils"

HERMETIC_HOME = Dir.mktmpdir("docker-api-ng-hermetic-home")
ENV["HOME"] = HERMETIC_HOME
ENV["USERPROFILE"] = HERMETIC_HOME
Minitest.after_run { FileUtils.remove_entry(HERMETIC_HOME, true) }

require "docker/api"
require_relative "support/http_fixtures"
