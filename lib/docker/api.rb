# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

require "json" unless defined?(JSON)
require "net/http" unless defined?(Net::HTTP)
require "openssl" unless defined?(OpenSSL)
require "socket" unless defined?(Socket)
require "stringio" unless defined?(StringIO)
require "uri" unless defined?(URI)

# The `docker-api` gem also owns the `Docker` namespace. This gem reopens it
# additively and defines nothing directly on it, so both can be loaded into one
# process -- which is what makes a gradual migration possible rather than a
# flag day.
module Docker
  # A Ruby client for the modern Docker Engine API.
  #
  # The complete API surface is generated from Docker's own OpenAPI
  # specification and reachable through {Client#operations}; an ergonomic
  # hand-written layer of collections and resources sits on top of it.
  #
  # @example Talking to the local daemon
  #   client = Docker::API::Client.new
  #   client.system.info["ServerVersion"]
  #
  # @example Two daemons at once, with no shared state
  #   local = Docker::API::Client.new
  #   build = Docker::API::Client.new(url: "tcp://build.internal:2376")
  module API
    require_relative "api/version"
    require_relative "api/errors"
    require_relative "api/response"
    require_relative "api/query"
    require_relative "api/path"
    require_relative "api/body"
    require_relative "api/platform"
    require_relative "api/tar"
    require_relative "api/transport/base"
    require_relative "api/transport/unix"
    require_relative "api/transport/tcp"
    require_relative "api/transport/tls"
    require_relative "api/transport/named_pipe"
    require_relative "api/transport/fake"
    require_relative "api/transport"
    require_relative "api/session"
    require_relative "api/stream"
    require_relative "api/connection"
    require_relative "api/config"
    require_relative "api/auth"
    require_relative "api/operations"
    require_relative "api/collection"
    require_relative "api/resource"
    require_relative "api/resources/exec"
    require_relative "api/resources/container"
    require_relative "api/resources/image"
    require_relative "api/resources/network"
    require_relative "api/resources/volume"
    require_relative "api/collections/containers"
    require_relative "api/collections/images"
    require_relative "api/collections/networks"
    require_relative "api/collections/volumes"
    require_relative "api/collections/system"
    require_relative "api/client"
  end
end
