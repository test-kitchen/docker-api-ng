# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

require_relative "text"

module Generator
  # Emits the low-level operations layer: one Ruby method per Engine API
  # operation, generated from the specification.
  #
  # The output is deliberately plain. There is no `define_method`, no shared
  # dispatch helper and no cleverness -- every method is spelled out, so it can
  # be read, grepped, documented by YARD and stepped through in a debugger. A
  # metaprogrammed layer would be shorter to generate and considerably worse to
  # live with.
  class OperationsEmitter
    # @param operations [Array<Generator::Operation>]
    # @param api_version [String] the version being generated from
    def initialize(operations, api_version:)
      @operations = operations
      @api_version = api_version
    end

    # @return [String] Ruby source
    def render
      lines = []
      lines << header
      lines << ""
      lines << "module Docker"
      lines << "  module API"
      lines << class_documentation
      lines << "    class Operations"
      lines << "      # @param connection [Docker::API::Connection] the connection to issue requests on"
      lines << "      def initialize(connection)"
      lines << "        @connection = connection"
      lines << "      end"
      lines << ""
      lines << "      # @return [Docker::API::Connection] the connection in use"
      lines << "      attr_reader :connection"
      lines << ""
      lines << @operations.map { |operation| render_operation(operation) }.join("\n")
      lines << "    end"
      lines << "  end"
      lines << "end"
      "#{lines.join("\n")}\n"
    end

    private

    # @return [String]
    def header
      <<~BANNER.rstrip
        # frozen_string_literal: true
        #
        # Copyright 2026 Tim Smith
        # SPDX-License-Identifier: Apache-2.0
        #
        # GENERATED -- do not edit.
        #
        # Source:    data/swagger/v#{@api_version}.yaml (Docker Engine API v#{@api_version})
        # Generator: tools/generator/operations_emitter.rb
        # Regenerate: bundle exec rake api:generate
        # Upgrade:    bundle exec rake api:sync[1.56]
        #
        # Editing this file by hand means the next regeneration silently reverts
        # your change. Fix the emitter or the vendored specification instead.
      BANNER
    end

    # @return [String]
    def class_documentation
      <<~DOC.rstrip
        # Every operation the Docker Engine API defines, one method each.
        #
        # This layer is generated from Docker's own specification, so it is
        # complete by construction: if the daemon documents an endpoint, there is
        # a method for it, with every parameter that endpoint accepts. It is also
        # public API rather than an escape hatch -- reach for it directly whenever
        # the ergonomic layer has not grown sugar for what you need.
            #
        # Methods take keyword arguments named after the specification's
        # parameters, return a {Docker::API::Response}, and raise a
        # {Docker::API::Error} subclass for any status the endpoint does not
        # document as success.
            #
        # @example Calling an endpoint with no ergonomic wrapper
        #   client.operations.container_prune(filters: { "until" => ["24h"] })
            #
        # @example Streaming, by passing a block
        #   client.operations.system_events { |chunk| puts chunk }
      DOC
        .split("\n").map { |line| line.strip.empty? ? "" : "    #{line.lstrip}" }.join("\n")
    end

    # @param operation [Generator::Operation]
    # @return [String]
    def render_operation(operation)
      signature = render_signature(operation)
      +"" << render_docs(operation) << "      def #{operation.method_name}#{signature}\n" <<
        render_body(operation) << "      end\n"
    end

    # Long signatures are wrapped one keyword per line.
    #
    # This file is committed and reviewed, so a diff that changes one parameter
    # should touch one line. A 700-character signature turns every regeneration
    # into an unreadable blob and hides exactly the change worth seeing.
    #
    # @return [String]
    def render_signature(operation)
      args = operation.required_params.map { |p| "#{p.ruby_name}:" } +
        operation.optional_params.map { |p| "#{p.ruby_name}: nil" }
      args << "&block"

      inline = "(#{args.join(", ")})"
      return inline if inline.length <= 96

      "(\n#{args.map { |arg| "        #{arg}" }.join(",\n")}\n      )"
    end

    # @return [String]
    def render_docs(operation)
      lines = []
      summary = Text.summarize(operation.summary) || operation.id
      lines.concat(Text.wrap(summary))

      detail = Text.summarize(operation.description, limit: 400)
      if detail && detail != summary
        lines << "      #"
        lines.concat(Text.wrap(detail))
      end

      lines << "      #"
      lines << "      # @!method #{operation.method_name}"
      lines << "      # Engine API: #{operation.verb.to_s.upcase} #{operation.path}"
      lines << "      #"

      (operation.required_params + operation.optional_params).each do |param|
        described = Text.summarize(param.description, limit: 160)
        optional = param.required? ? "" : ", nil"
        text = "@param #{param.ruby_name} [#{param.ruby_type}#{optional}] #{described}".rstrip
        text += " (body parameter '#{param.name}' in the API specification)" if param.location == :body
        if param.location != :body && param.renamed?
          text += " (sent to the daemon as '#{param.name}')"
        end
        lines.concat(Text.wrap(text, width: 72))
      end

      lines << "      # @yieldparam chunk [String] successive body chunks, when a block is given"
      lines << "      # @return [Docker::API::Response]"
      operation.error_codes.sort.each do |status, description|
        klass = error_class_name(status)
        lines.concat(Text.wrap("@raise [Docker::API::#{klass}] #{status} -- #{Text.summarize(description, limit: 90)}", width: 72))
      end

      "#{lines.join("\n")}\n"
    end

    # Mirrors Docker::API::Error.klass_for, which is the runtime authority.
    #
    # @param status [Integer]
    # @return [String]
    def error_class_name(status)
      {
        304 => "NotModified", 400 => "BadRequest", 401 => "Unauthorized",
        403 => "Forbidden", 404 => "NotFound", 409 => "Conflict",
      }.fetch(status) { status.between?(500, 599) ? "ServerError" : "ClientError" }
    end

    # @return [String]
    def render_body(operation)
      lines = ["        connection.request("]
      lines << "          :#{operation.verb},"
      lines << "          #{render_path(operation)},"

      unless operation.query_params.empty?
        pairs = operation.query_params.map { |p| "#{p.name.inspect} => #{p.ruby_name}" }
        lines << render_hash("query", pairs)
      end

      unless operation.header_params.empty?
        pairs = operation.header_params.map { |p| "#{p.name.inspect} => #{p.ruby_name}" }
        lines << render_hash("headers", pairs, suffix: ".compact")
      end

      lines << "          body: body," if operation.body_param
      lines << "          expects: #{operation.success_codes.inspect},"
      lines << "          operation: #{operation.method_name.to_s.inspect},"
      lines << "          &block"
      lines << "        )"
      "#{lines.join("\n")}\n"
    end

    # @param label [String] the keyword argument name
    # @param pairs [Array<String>] rendered "key" => value pairs
    # @param suffix [String] anything to append after the closing brace
    # @return [String]
    def render_hash(label, pairs, suffix: "")
      inline = "          #{label}: { #{pairs.join(", ")} }#{suffix},"
      return inline if inline.length <= 110

      body = pairs.map { |pair| "            #{pair}," }.join("\n")
      "          #{label}: {\n#{body}\n          }#{suffix},"
    end

    # Path parameters are interpolated through Path.escape, which leaves "/"
    # and ":" alone so image references survive intact.
    #
    # @return [String]
    def render_path(operation)
      return operation.path.inspect if operation.path_params.empty?

      interpolated = operation.path.gsub(/\{(\w+)\}/) do
        param = operation.path_params.find { |p| p.name == Regexp.last_match(1) }
        param ? "\#{Path.escape(#{param.ruby_name})}" : Regexp.last_match(0)
      end
      "\"#{interpolated}\""
    end
  end
end
