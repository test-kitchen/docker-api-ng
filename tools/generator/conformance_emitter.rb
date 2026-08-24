# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Generator
  # Emits a conformance test for every operation.
  #
  # Committed generated code is only trustworthy if a bad generator change
  # fails loudly. These tests pin the contract each method is supposed to
  # honour -- its verb, its path template, and every parameter the
  # specification defines -- by driving the real method through a scripted
  # transport and reading the bytes it actually put on the wire.
  #
  # The parameter assertions matter most. Silently dropping a query parameter
  # is the defect that made `docker-api`'s `Container.create` ignore
  # `platform`, and the daemon does not complain when it happens: it ignores
  # what it cannot parse and quietly does something else. Asserting every
  # parameter reaches the wire is the only way that failure mode shows up as a
  # test rather than as a confused bug report.
  class ConformanceEmitter
    # Paths the connection deliberately does not version-prefix, because they
    # are how it discovers which version to use. Kept in step with
    # Docker::API::Connection::UNVERSIONED by a test.
    UNVERSIONED = ["/_ping"].freeze

    # @param operations [Array<Generator::Operation>]
    # @param api_version [String]
    def initialize(operations, api_version:)
      @operations = operations
      @api_version = api_version
    end

    # @return [String] Ruby source for a minitest suite
    def render
      lines = [header, "", "require \"spec_helper\"", ""]
      lines << "describe \"generated operations\" do"
      lines << harness
      @operations.each { |operation| lines << render_test(operation) }
      lines << "end"
      "#{lines.join("\n")}\n"
    end

    private

    # @return [String]
    def header
      <<~BANNER.rstrip
        # frozen_string_literal: true
        #
        # GENERATED -- do not edit.
        #
        # Source:     data/swagger/v#{@api_version}.yaml (Docker Engine API v#{@api_version})
        # Generator:  tools/generator/conformance_emitter.rb
        # Regenerate: bundle exec rake api:generate
        #
        # One test per operation, asserting the verb, the path template and that
        # every parameter the specification defines actually reaches the wire.
      BANNER
    end

    # @return [String]
    def harness
      <<~RUBY.rstrip
        #{"  "}# Drives a real operation through a scripted transport and returns the
          # request bytes it produced.
          def wire(status)
            fake = Docker::API::Transport::Fake.new([http_response(status, {})])
            connection = Docker::API::Connection.new(transport: fake, api_version: "#{@api_version}")
            yield Docker::API::Operations.new(connection)
            fake.finish
            CGI.unescape(fake.requests.first.to_s)
          end
      RUBY
    end

    # @param operation [Generator::Operation]
    # @return [String]
    def render_test(operation)
      arguments = (operation.required_params + operation.optional_params)
        .map { |param| "#{param.ruby_name}: #{sample(param)}" }

      lines = []
      lines << ""
      lines << "  it \"#{operation.method_name} sends #{operation.verb.to_s.upcase} " \
               "#{operation.path} with every documented parameter\" do"
      lines << "    request = wire(#{operation.success_codes.first}) do |operations|"
      lines << "      operations.#{operation.method_name}#{arguments.empty? ? "" : "("}"
      arguments.each_with_index do |argument, index|
        lines << "        #{argument}#{index == arguments.size - 1 ? "" : ","}"
      end
      lines << "      #{arguments.empty? ? "" : ")"}".rstrip
      lines << "    end"
      lines << ""
      lines << "    _(request).must_include \"#{operation.verb.to_s.upcase} #{prefix(operation)}#{expected_path(operation)}\""
      operation.query_params.each do |param|
        lines << "    _(request).must_include \"#{param.name}=\""
      end
      # Header names are compared in lower case because Net::HTTP canonicalises
      # them on the way out: the specification's "Content-type" goes on the
      # wire as "Content-Type".
      operation.header_params.each do |param|
        lines << "    _(request.downcase).must_include \"#{param.name.downcase}: \""
      end
      lines << "  end"
      lines.join("\n")
    end

    # @param operation [Generator::Operation]
    # @return [String] the version prefix this path is sent with, if any
    def prefix(operation)
      UNVERSIONED.include?(operation.path) ? "" : "/v#{@api_version}"
    end

    # @param operation [Generator::Operation]
    # @return [String] the path with sample values substituted for templates
    def expected_path(operation)
      operation.path.gsub(/\{(\w+)\}/) { sample_path_value(Regexp.last_match(1)) }
    end

    # @param name [String]
    # @return [String]
    def sample_path_value(name)
      "sample-#{name.downcase}"
    end

    # A value of the right type for each parameter, so the generated call is
    # both valid Ruby and representative of a real one.
    #
    # @param param [Generator::Parameter]
    # @return [String] Ruby source for a sample value
    def sample(param)
      case param.location
      when :path then sample_path_value(param.name).inspect
      when :body then '{ "sample" => "body" }'
      else
        case param.type
        when "boolean" then "true"
        when "integer" then "1"
        when "array" then '["sample"]'
        else '"sample"'
        end
      end
    end
  end
end
