# frozen_string_literal: true

require_relative "integration_helper"

describe "images on a real daemon" do
  it "pulls an image, reporting progress" do
    events = []
    image = client.images.pull(IntegrationHelper::TEST_IMAGE) { |event| events << event }

    _(image.tags).must_include IntegrationHelper::TEST_IMAGE
    _(events).wont_be_empty
  end

  it "reports a missing image as absent rather than raising" do
    _(client.images.exist?("#{IntegrationHelper::PREFIX}/nothing:here")).must_equal false
  end

  it "builds from a Dockerfile held in memory" do
    tag = "#{IntegrationHelper::PREFIX}-build:#{Process.pid}"
    output = []
    image = client.images.build(
      dockerfile: "FROM #{IntegrationHelper::TEST_IMAGE}\nRUN echo built > /marker\n",
      tag: tag
    ) { |event| output << event }

    _(image.tags).must_include tag
    _(output).wont_be_empty

    container = client.containers.create(image: tag, cmd: %w{cat /marker})
    container.start
    container.wait
    _(container.logs).must_include "built"
    discard(container)

    image.remove(force: true)
  end

  it "reports a build failure rather than returning a broken image" do
    error = _ {
      client.images.build(
        dockerfile: "FROM #{IntegrationHelper::TEST_IMAGE}\nRUN exit 1\n",
        tag: "#{IntegrationHelper::PREFIX}-fail:#{Process.pid}"
      )
    }.must_raise Docker::API::Error

    _(error.message).must_match(/build failed|non-zero code/i)
  end
end
