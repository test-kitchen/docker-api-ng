# frozen_string_literal: true

require "spec_helper"

describe Docker::API::Body do
  it "converts snake_case keys to the daemon's PascalCase" do
    _(Docker::API::Body.build(image: "alpine", working_dir: "/srv"))
      .must_equal("Image" => "alpine", "WorkingDir" => "/srv")
  end

  it "leaves keys that already look like the daemon's alone" do
    _(Docker::API::Body.build("HostConfig" => { "Binds" => [] }))
      .must_equal("HostConfig" => { "Binds" => [] })
  end

  # Nested maps have keys that belong to the user -- labels, exposed ports,
  # sysctls. Converting them would mangle "com.example/team" into nonsense.
  it "does not touch nested keys, which are frequently data" do
    body = Docker::API::Body.build(
      labels: { "com.example/team" => "infra" },
      host_config: { "PortBindings" => { "80/tcp" => [{ "HostPort" => "8080" }] } }
    )

    _(body["Labels"]).must_equal("com.example/team" => "infra")
    _(body["HostConfig"]["PortBindings"]).must_equal("80/tcp" => [{ "HostPort" => "8080" }])
  end

  it "drops nils so an unset option is absent rather than null" do
    _(Docker::API::Body.build(image: "alpine", user: nil)).must_equal("Image" => "alpine")
  end

  it "handles the names Docker spells unusually" do
    _(Docker::API::Body.camelize(:entrypoint)).must_equal "Entrypoint"
    _(Docker::API::Body.camelize(:tty)).must_equal "Tty"
    _(Docker::API::Body.camelize(:mac_address)).must_equal "MacAddress"
    _(Docker::API::Body.camelize(:exposed_ports)).must_equal "ExposedPorts"
  end
end
