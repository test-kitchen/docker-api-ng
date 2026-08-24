# frozen_string_literal: true

require "spec_helper"

# Integration tests talk to a real Docker daemon and are therefore opt-in:
#
#   DOCKER_API_NG_INTEGRATION=1 bundle exec rake integration
#
# Everything else in spec/ is hermetic. Keeping these separate means the
# default suite stays fast and runs anywhere, while the assertions that can
# only be made against a real daemon still get made somewhere.
module IntegrationHelper
  # A small image that exists for every architecture CI might run on.
  TEST_IMAGE = "alpine:3.20"

  # Everything this suite creates is named with this prefix, so a crashed run
  # leaves behind something obviously disposable rather than a mystery.
  PREFIX = "docker-api-ng-test"

  def self.enabled?
    !ENV["DOCKER_API_NG_INTEGRATION"].to_s.empty?
  end

  def client
    @client ||= Docker::API::Client.new
  end

  def unique(suffix)
    "#{PREFIX}-#{suffix}-#{Process.pid}"
  end

  # Remove a container whether or not it exists, so cleanup never fails a test
  # that had already passed.
  def discard(container)
    container&.remove(force: true, volumes: true)
  rescue Docker::API::Error
    nil
  end

  def skip_unless_integration
    skip "set DOCKER_API_NG_INTEGRATION=1 to run integration tests" unless IntegrationHelper.enabled?
  end
end

module Minitest
  class Test
    include IntegrationHelper

    def before_setup
      super
      skip_unless_integration
    end
  end
end
