# frozen_string_literal: true

require "spec_helper"

describe Docker::API::Error do
  it "maps status codes onto specific subclasses" do
    {
      304 => Docker::API::NotModified,
      400 => Docker::API::BadRequest,
      401 => Docker::API::Unauthorized,
      403 => Docker::API::Forbidden,
      404 => Docker::API::NotFound,
      409 => Docker::API::Conflict,
      500 => Docker::API::ServerError,
      503 => Docker::API::ServerError,
    }.each do |status, klass|
      error = Docker::API::Error.for(status: status, operation: "container_start")
      _(error).must_be_kind_of klass
    end
  end

  it "falls back by range for statuses without a specific class" do
    _(Docker::API::Error.for(status: 418)).must_be_kind_of Docker::API::ClientError
    _(Docker::API::Error.for(status: 599)).must_be_kind_of Docker::API::ServerError
  end

  it "surfaces the daemon's own message alongside the operation" do
    response = Docker::API::Response.new(
      status: 409, headers: {}, body: '{"message":"container already started"}'
    )
    error = Docker::API::Error.for(status: 409, operation: "container_start", response: response)

    _(error.message).must_include "container already started"
    _(error.message).must_include "container_start"
    _(error.status).must_equal 409
    _(error.operation).must_equal "container_start"
  end

  it "uses a non-JSON body rather than reporting nothing" do
    response = Docker::API::Response.new(status: 500, headers: {}, body: "something went wrong")
    error = Docker::API::Error.for(status: 500, operation: "image_build", response: response)

    _(error.message).must_include "something went wrong"
  end

  it "still composes a message when the daemon said nothing at all" do
    error = Docker::API::Error.for(status: 500, operation: "system_info")
    _(error.message).must_include "system_info"
    _(error.message).must_include "500"
  end

  it "keeps every error under the one root, so callers rescue once" do
    [
      Docker::API::ConnectionError, Docker::API::TimeoutError, Docker::API::BadRequest,
      Docker::API::Unauthorized, Docker::API::Forbidden, Docker::API::NotFound,
      Docker::API::NotModified, Docker::API::Conflict, Docker::API::ServerError,
      Docker::API::VersionUnsupported, Docker::API::StreamError, Docker::API::ClientError,
    ].each { |klass| _(klass.ancestors).must_include Docker::API::Error }
  end
end
