# frozen_string_literal: true

require_relative "integration_helper"

describe "networks and volumes on a real daemon" do
  it "creates a network, attaches a container and tidies up" do
    network = client.networks.create(unique("net"))
    container = nil

    begin
      client.images.ensure(IntegrationHelper::TEST_IMAGE)
      container = client.containers.create(
        image: IntegrationHelper::TEST_IMAGE, name: unique("net-member"), cmd: %w{sleep 120}
      )
      container.start
      network.connect(container, aliases: %w{member})

      _(client.networks.get(network.id).containers.keys).must_include container.id

      network.disconnect(container)
      _(client.networks.get(network.id).containers.keys).wont_include container.id
    ensure
      discard(container)
      begin
        network.remove
      rescue Docker::API::Error
        nil
      end
    end
  end

  it "does not mind losing a race to create a shared network" do
    name = unique("shared")
    first = client.networks.ensure(name)
    second = client.networks.ensure(name)

    _(first.id).must_equal second.id
    first.remove
  end

  it "creates and removes a volume" do
    volume = client.volumes.create(unique("vol"), labels: { "docker-api-ng" => "integration" })

    _(volume.driver).must_equal "local"
    _(volume.mountpoint).wont_be_nil
    _(client.volumes.get(volume.name).labels).must_equal("docker-api-ng" => "integration")

    volume.remove
    _(client.volumes.find(volume.name)).must_be_nil
  end
end
