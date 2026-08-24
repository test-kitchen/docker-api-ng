# frozen_string_literal: true
#
# Copyright 2026 Tim Smith
# SPDX-License-Identifier: Apache-2.0

module Docker
  module API
    # The gem's own version.
    VERSION = "0.2.0"

    # The newest Engine API version this gem vendors a specification for.
    # Requests are never made against a version above this, even when the
    # daemon offers one, because the generated layer only knows this shape.
    MAX_API_VERSION = "1.55"

    # The oldest Engine API version this gem will talk to. Docker 20.10 is the
    # oldest release still plausibly in service; below it, enough of the API
    # differs that failing loudly beats failing mysteriously.
    MIN_API_VERSION = "1.41"
  end
end
