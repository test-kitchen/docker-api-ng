# frozen_string_literal: true

require "spec_helper"

# spec_helper states that everything outside spec/integration is hermetic:
# "no Docker daemon, no network, no reads of the real home directory, and no
# sleeping". The first two are structurally true -- Transport::Fake is the only
# way out. The third was not, and nothing was checking.
describe "the unit suite's hermeticity" do
  it "does not resolve credentials from the real Docker configuration" do
    _(Docker::API::Auth.resolve(nil)).must_be_nil
    _(Docker::API::Auth.resolve("ghcr.io")).must_be_nil
  end

  it "points Dir.home somewhere disposable" do
    _(Dir.home).must_equal HERMETIC_HOME
    _(Dir.children(Dir.home)).must_be_empty
  end

  # The assertion that actually matters, stated in the terms of the leak: a
  # pull with no auth: must not put a credential on the wire.
  it "sends no registry credential on a pull that was given none" do
    client, fake = faked_client([
      http_response(200, %({"status":"Pulling"}\n)),
      http_response(200, { "Id" => "sha256:x", "RepoTags" => ["alpine:3.20"] }),
    ])
    client.images.pull("alpine:3.20")
    fake.finish

    _(fake.requests.first).wont_include "X-Registry-Auth"
  end

  it "still sends the credential a caller passes explicitly" do
    client, fake = faked_client([
      http_response(200, %({"status":"Pulling"}\n)),
      http_response(200, { "Id" => "sha256:x", "RepoTags" => ["alpine:3.20"] }),
    ])
    client.images.pull("alpine:3.20", auth: "stub-token")
    fake.finish

    _(fake.requests.first).must_include "X-Registry-Auth: stub-token"
  end

  # A real config in the hermetic home is still read, so the redirect has not
  # simply disabled the feature -- Auth's own specs pass config_path directly
  # and must keep working.
  it "still reads a configuration it is pointed at" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "config.json")
      File.write(path, JSON.generate("auths" => { "ghcr.io" => { "auth" => ["bob:token"].pack("m0") } }))

      _(Docker::API::Auth.resolve("ghcr.io", config_path: path)).wont_be_nil
    end
  end
end
