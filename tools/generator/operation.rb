# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Generator
  # Ruby's reserved words, which a parameter name may collide with.
  #
  # Docker has query parameters called `until` on the container-logs and
  # events endpoints. Ruby will accept `def f(until: nil)` as a definition and
  # then refuse to parse any reference to it in the body, because the parser
  # sees the start of a loop. Colliding names get a trailing underscore, and
  # the daemon still receives the original spelling.
  RESERVED_WORDS = %w{
    alias and BEGIN begin break case class def defined? do else elsif END end
    ensure false for if in module next nil not or redo rescue retry return
    self super then true undef unless until when while yield
    __FILE__ __LINE__ __ENCODING__ __method__
  }.freeze

  # One parameter of one Engine API operation.
  #
  # The wire name and the Ruby name are kept separate on purpose. Docker's
  # parameter names are a mixture of conventions -- `all`, `fromImage`,
  # `one-shot`, `X-Registry-Auth` -- and the generated methods should read like
  # Ruby while still putting the daemon's exact spelling on the wire.
  Parameter = Struct.new(
    :name, :location, :type, :required, :description, :collection_format,
    keyword_init: true
  ) do
    # Body parameters are named inconsistently in the specification
    # (`body`, `execConfig`, `inputStream`, `tarContext`, and nine others).
    # They are all the request body, so they are all `body:` here, and the
    # specification's own name is recorded in the documentation instead.
    #
    # @return [Symbol] the Ruby keyword for this parameter
    def ruby_name
      return :body if location == :body

      snake = name.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .tr("-", "_")
        .downcase

      RESERVED_WORDS.include?(snake) ? :"#{snake}_" : snake.to_sym
    end

    # @return [Boolean] whether the Ruby name had to differ from the wire name
    def renamed?
      ruby_name.to_s != name
    end

    # @return [Boolean] whether the parameter must be supplied
    def required?
      required == true
    end

    # @return [String] the Ruby type for documentation and signatures
    def ruby_type
      case type
      when "boolean" then "Boolean"
      when "integer" then "Integer"
      when "array" then "Array<String>"
      when "schema" then "Hash"
      else "String"
      end
    end

    # @return [String] the RBS type
    def rbs_type
      case type
      when "boolean" then "bool"
      when "integer" then "Integer"
      when "array" then "Array[untyped]"
      when "schema" then "Hash[String, untyped] | String | IO"
      else "String"
      end
    end
  end

  # One Engine API operation, reduced to what the emitters need.
  Operation = Struct.new(
    :id, :verb, :path, :parameters, :responses, :summary, :description, :tag,
    keyword_init: true
  ) do
    # `ContainerCreate` becomes `container_create`; `ImageGetAll` becomes
    # `image_get_all`. The first substitution keeps runs of capitals together
    # so a hypothetical `GetTLSInfo` becomes `get_tls_info` and not
    # `get_t_l_s_info`.
    #
    # @return [Symbol]
    def method_name
      id.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .downcase
        .to_sym
    end

    # @return [Array<Generator::Parameter>]
    def path_params
      parameters.select { |p| p.location == :path }
    end

    # @return [Array<Generator::Parameter>]
    def query_params
      parameters.select { |p| p.location == :query }
    end

    # @return [Array<Generator::Parameter>]
    def header_params
      parameters.select { |p| p.location == :header }
    end

    # @return [Generator::Parameter, nil]
    def body_param
      parameters.find { |p| p.location == :body }
    end

    # Parameters that must be supplied, in a stable order: path parameters
    # first because they are the subject of the call, then a required body.
    #
    # @return [Array<Generator::Parameter>]
    def required_params
      path_params + parameters.select { |p| p.location != :path && p.required? }
    end

    # @return [Array<Generator::Parameter>]
    def optional_params
      (query_params + header_params + [body_param].compact).reject(&:required?)
    end

    # @return [Array<Integer>] statuses the daemon documents as success
    def success_codes
      codes = responses.keys.select { |code| (200..299).cover?(code) }
      codes.empty? ? [200] : codes.sort
    end

    # @return [Hash{Integer => String}] documented failures
    def error_codes
      responses.reject { |code, _| (200..299).cover?(code) }
    end
  end
end
