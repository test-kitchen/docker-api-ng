# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Docker
  module API
    # What a command run inside a container produced.
    #
    # A non-zero {#exit_code} is returned rather than raised. Whether a failing
    # command is an error depends entirely on why it was run -- a test runner
    # expects failures, a provisioning step does not -- so the decision belongs
    # to the caller. {#success?} and {#check!} are there for the common cases.
    ExecResult = Struct.new(:stdout, :stderr, :exit_code, keyword_init: true) do
      # @return [Boolean] whether the command exited zero
      def success?
        exit_code == 0
      end

      # @return [self]
      # @raise [Docker::API::Error] if the command exited non-zero
      def check!
        return self if success?

        raise Error.new(
          "command exited #{exit_code}: #{(stderr.to_s.empty? ? stdout : stderr).to_s.strip}",
          operation: "exec"
        )
      end

      # @return [String] stdout and stderr in the order they were produced
      def output
        "#{stdout}#{stderr}"
      end
    end
  end
end
