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
      # Nil is not success. The daemon reports a null exit code while an exec
      # is still being reaped, and treating that as zero fails open on exactly
      # the question this struct exists to answer.
      #
      # @return [Boolean] whether the command exited zero
      def success?
        exit_code == 0
      end

      # @return [self]
      # @raise [Docker::API::Error] if the command exited non-zero, or if the
      #   daemon did not report an exit code at all
      def check!
        return self if success?

        raise Error.new(check_message, operation: "exec")
      end

      # @return [String] stdout and stderr in the order they were produced
      def output
        "#{stdout}#{stderr}"
      end

      private

      # @return [String]
      def check_message
        return "the daemon reported no exit code for this command, so whether it succeeded is unknown" if exit_code.nil?

        "command exited #{exit_code}: #{(stderr.to_s.empty? ? stdout : stderr).to_s.strip}"
      end
    end
  end
end
