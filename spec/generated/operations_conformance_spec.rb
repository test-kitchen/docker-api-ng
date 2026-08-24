# frozen_string_literal: true
#
# GENERATED -- do not edit.
#
# Source:     data/swagger/v1.55.yaml (Docker Engine API v1.55)
# Generator:  tools/generator/conformance_emitter.rb
# Regenerate: bundle exec rake api:generate
#
# One test per operation, asserting the verb, the path template and that
# every parameter the specification defines actually reaches the wire.

require "cgi"
require "spec_helper"

describe "generated operations" do
  # Drives a real operation through a scripted transport and returns the
  # request bytes it produced.
  def wire(status)
    fake = Docker::API::Transport::Fake.new([http_response(status, {})])
    connection = Docker::API::Connection.new(transport: fake, api_version: "1.55")
    yield Docker::API::Operations.new(connection)
    fake.finish
    CGI.unescape(fake.requests.first.to_s)
  end

  it "config_create sends POST /configs/create with every documented parameter" do
    request = wire(201) do |operations|
      operations.config_create(
        body: { "sample" => "body" }
      )
    end

    _(request).must_include "POST /v1.55/configs/create"
  end

  it "config_delete sends DELETE /configs/{id} with every documented parameter" do
    request = wire(204) do |operations|
      operations.config_delete(
        id: "sample-id"
      )
    end

    _(request).must_include "DELETE /v1.55/configs/sample-id"
  end

  it "config_inspect sends GET /configs/{id} with every documented parameter" do
    request = wire(200) do |operations|
      operations.config_inspect(
        id: "sample-id"
      )
    end

    _(request).must_include "GET /v1.55/configs/sample-id"
  end

  it "config_list sends GET /configs with every documented parameter" do
    request = wire(200) do |operations|
      operations.config_list(
        filters: "sample"
      )
    end

    _(request).must_include "GET /v1.55/configs"
    _(request).must_include "filters="
  end

  it "config_update sends POST /configs/{id}/update with every documented parameter" do
    request = wire(200) do |operations|
      operations.config_update(
        id: "sample-id",
        version: 1,
        body: { "sample" => "body" }
      )
    end

    _(request).must_include "POST /v1.55/configs/sample-id/update"
    _(request).must_include "version="
  end

  it "container_archive sends GET /containers/{id}/archive with every documented parameter" do
    request = wire(200) do |operations|
      operations.container_archive(
        id: "sample-id",
        path: "sample"
      )
    end

    _(request).must_include "GET /v1.55/containers/sample-id/archive"
    _(request).must_include "path="
  end

  it "container_archive_info sends HEAD /containers/{id}/archive with every documented parameter" do
    request = wire(200) do |operations|
      operations.container_archive_info(
        id: "sample-id",
        path: "sample"
      )
    end

    _(request).must_include "HEAD /v1.55/containers/sample-id/archive"
    _(request).must_include "path="
  end

  it "container_attach sends POST /containers/{id}/attach with every documented parameter" do
    request = wire(200) do |operations|
      operations.container_attach(
        id: "sample-id",
        detach_keys: "sample",
        logs: true,
        stream: true,
        stdin: true,
        stdout: true,
        stderr: true
      )
    end

    _(request).must_include "POST /v1.55/containers/sample-id/attach"
    _(request).must_include "detachKeys="
    _(request).must_include "logs="
    _(request).must_include "stream="
    _(request).must_include "stdin="
    _(request).must_include "stdout="
    _(request).must_include "stderr="
  end

  it "container_attach_websocket sends GET /containers/{id}/attach/ws with every documented parameter" do
    request = wire(200) do |operations|
      operations.container_attach_websocket(
        id: "sample-id",
        detach_keys: "sample",
        logs: true,
        stream: true,
        stdin: true,
        stdout: true,
        stderr: true
      )
    end

    _(request).must_include "GET /v1.55/containers/sample-id/attach/ws"
    _(request).must_include "detachKeys="
    _(request).must_include "logs="
    _(request).must_include "stream="
    _(request).must_include "stdin="
    _(request).must_include "stdout="
    _(request).must_include "stderr="
  end

  it "container_changes sends GET /containers/{id}/changes with every documented parameter" do
    request = wire(200) do |operations|
      operations.container_changes(
        id: "sample-id"
      )
    end

    _(request).must_include "GET /v1.55/containers/sample-id/changes"
  end

  it "container_create sends POST /containers/create with every documented parameter" do
    request = wire(201) do |operations|
      operations.container_create(
        body: { "sample" => "body" },
        name: "sample",
        platform: "sample"
      )
    end

    _(request).must_include "POST /v1.55/containers/create"
    _(request).must_include "name="
    _(request).must_include "platform="
  end

  it "container_delete sends DELETE /containers/{id} with every documented parameter" do
    request = wire(204) do |operations|
      operations.container_delete(
        id: "sample-id",
        v: true,
        force: true,
        link: true
      )
    end

    _(request).must_include "DELETE /v1.55/containers/sample-id"
    _(request).must_include "v="
    _(request).must_include "force="
    _(request).must_include "link="
  end

  it "container_export sends GET /containers/{id}/export with every documented parameter" do
    request = wire(200) do |operations|
      operations.container_export(
        id: "sample-id"
      )
    end

    _(request).must_include "GET /v1.55/containers/sample-id/export"
  end

  it "container_inspect sends GET /containers/{id}/json with every documented parameter" do
    request = wire(200) do |operations|
      operations.container_inspect(
        id: "sample-id",
        size: true
      )
    end

    _(request).must_include "GET /v1.55/containers/sample-id/json"
    _(request).must_include "size="
  end

  it "container_kill sends POST /containers/{id}/kill with every documented parameter" do
    request = wire(204) do |operations|
      operations.container_kill(
        id: "sample-id",
        signal: "sample"
      )
    end

    _(request).must_include "POST /v1.55/containers/sample-id/kill"
    _(request).must_include "signal="
  end

  it "container_list sends GET /containers/json with every documented parameter" do
    request = wire(200) do |operations|
      operations.container_list(
        all: true,
        limit: 1,
        size: true,
        filters: "sample"
      )
    end

    _(request).must_include "GET /v1.55/containers/json"
    _(request).must_include "all="
    _(request).must_include "limit="
    _(request).must_include "size="
    _(request).must_include "filters="
  end

  it "container_logs sends GET /containers/{id}/logs with every documented parameter" do
    request = wire(200) do |operations|
      operations.container_logs(
        id: "sample-id",
        follow: true,
        stdout: true,
        stderr: true,
        since: 1,
        until_: 1,
        timestamps: true,
        tail: "sample"
      )
    end

    _(request).must_include "GET /v1.55/containers/sample-id/logs"
    _(request).must_include "follow="
    _(request).must_include "stdout="
    _(request).must_include "stderr="
    _(request).must_include "since="
    _(request).must_include "until="
    _(request).must_include "timestamps="
    _(request).must_include "tail="
  end

  it "container_pause sends POST /containers/{id}/pause with every documented parameter" do
    request = wire(204) do |operations|
      operations.container_pause(
        id: "sample-id"
      )
    end

    _(request).must_include "POST /v1.55/containers/sample-id/pause"
  end

  it "container_prune sends POST /containers/prune with every documented parameter" do
    request = wire(200) do |operations|
      operations.container_prune(
        filters: "sample"
      )
    end

    _(request).must_include "POST /v1.55/containers/prune"
    _(request).must_include "filters="
  end

  it "container_rename sends POST /containers/{id}/rename with every documented parameter" do
    request = wire(204) do |operations|
      operations.container_rename(
        id: "sample-id",
        name: "sample"
      )
    end

    _(request).must_include "POST /v1.55/containers/sample-id/rename"
    _(request).must_include "name="
  end

  it "container_resize sends POST /containers/{id}/resize with every documented parameter" do
    request = wire(200) do |operations|
      operations.container_resize(
        id: "sample-id",
        h: 1,
        w: 1
      )
    end

    _(request).must_include "POST /v1.55/containers/sample-id/resize"
    _(request).must_include "h="
    _(request).must_include "w="
  end

  it "container_restart sends POST /containers/{id}/restart with every documented parameter" do
    request = wire(204) do |operations|
      operations.container_restart(
        id: "sample-id",
        signal: "sample",
        t: 1
      )
    end

    _(request).must_include "POST /v1.55/containers/sample-id/restart"
    _(request).must_include "signal="
    _(request).must_include "t="
  end

  it "container_start sends POST /containers/{id}/start with every documented parameter" do
    request = wire(204) do |operations|
      operations.container_start(
        id: "sample-id",
        detach_keys: "sample"
      )
    end

    _(request).must_include "POST /v1.55/containers/sample-id/start"
    _(request).must_include "detachKeys="
  end

  it "container_stats sends GET /containers/{id}/stats with every documented parameter" do
    request = wire(200) do |operations|
      operations.container_stats(
        id: "sample-id",
        stream: true,
        one_shot: true
      )
    end

    _(request).must_include "GET /v1.55/containers/sample-id/stats"
    _(request).must_include "stream="
    _(request).must_include "one-shot="
  end

  it "container_stop sends POST /containers/{id}/stop with every documented parameter" do
    request = wire(204) do |operations|
      operations.container_stop(
        id: "sample-id",
        signal: "sample",
        t: 1
      )
    end

    _(request).must_include "POST /v1.55/containers/sample-id/stop"
    _(request).must_include "signal="
    _(request).must_include "t="
  end

  it "container_top sends GET /containers/{id}/top with every documented parameter" do
    request = wire(200) do |operations|
      operations.container_top(
        id: "sample-id",
        ps_args: "sample"
      )
    end

    _(request).must_include "GET /v1.55/containers/sample-id/top"
    _(request).must_include "ps_args="
  end

  it "container_unpause sends POST /containers/{id}/unpause with every documented parameter" do
    request = wire(204) do |operations|
      operations.container_unpause(
        id: "sample-id"
      )
    end

    _(request).must_include "POST /v1.55/containers/sample-id/unpause"
  end

  it "container_update sends POST /containers/{id}/update with every documented parameter" do
    request = wire(200) do |operations|
      operations.container_update(
        id: "sample-id",
        body: { "sample" => "body" }
      )
    end

    _(request).must_include "POST /v1.55/containers/sample-id/update"
  end

  it "container_wait sends POST /containers/{id}/wait with every documented parameter" do
    request = wire(200) do |operations|
      operations.container_wait(
        id: "sample-id",
        condition: "sample"
      )
    end

    _(request).must_include "POST /v1.55/containers/sample-id/wait"
    _(request).must_include "condition="
  end

  it "put_container_archive sends PUT /containers/{id}/archive with every documented parameter" do
    request = wire(200) do |operations|
      operations.put_container_archive(
        id: "sample-id",
        path: "sample",
        body: { "sample" => "body" },
        no_overwrite_dir_non_dir: "sample",
        copy_uidgid: "sample"
      )
    end

    _(request).must_include "PUT /v1.55/containers/sample-id/archive"
    _(request).must_include "path="
    _(request).must_include "noOverwriteDirNonDir="
    _(request).must_include "copyUIDGID="
  end

  it "distribution_inspect sends GET /distribution/{name}/json with every documented parameter" do
    request = wire(200) do |operations|
      operations.distribution_inspect(
        name: "sample-name"
      )
    end

    _(request).must_include "GET /v1.55/distribution/sample-name/json"
  end

  it "container_exec sends POST /containers/{id}/exec with every documented parameter" do
    request = wire(201) do |operations|
      operations.container_exec(
        id: "sample-id",
        body: { "sample" => "body" }
      )
    end

    _(request).must_include "POST /v1.55/containers/sample-id/exec"
  end

  it "exec_inspect sends GET /exec/{id}/json with every documented parameter" do
    request = wire(200) do |operations|
      operations.exec_inspect(
        id: "sample-id"
      )
    end

    _(request).must_include "GET /v1.55/exec/sample-id/json"
  end

  it "exec_resize sends POST /exec/{id}/resize with every documented parameter" do
    request = wire(200) do |operations|
      operations.exec_resize(
        id: "sample-id",
        h: 1,
        w: 1
      )
    end

    _(request).must_include "POST /v1.55/exec/sample-id/resize"
    _(request).must_include "h="
    _(request).must_include "w="
  end

  it "exec_start sends POST /exec/{id}/start with every documented parameter" do
    request = wire(200) do |operations|
      operations.exec_start(
        id: "sample-id",
        body: { "sample" => "body" }
      )
    end

    _(request).must_include "POST /v1.55/exec/sample-id/start"
  end

  it "build_prune sends POST /build/prune with every documented parameter" do
    request = wire(200) do |operations|
      operations.build_prune(
        reserved_space: 1,
        max_used_space: 1,
        min_free_space: 1,
        all: true,
        filters: "sample"
      )
    end

    _(request).must_include "POST /v1.55/build/prune"
    _(request).must_include "reserved-space="
    _(request).must_include "max-used-space="
    _(request).must_include "min-free-space="
    _(request).must_include "all="
    _(request).must_include "filters="
  end

  it "image_attestations sends GET /images/{name}/attestations with every documented parameter" do
    request = wire(200) do |operations|
      operations.image_attestations(
        name: "sample-name",
        platform: ["sample"],
        type: ["sample"],
        statement: true
      )
    end

    _(request).must_include "GET /v1.55/images/sample-name/attestations"
    _(request).must_include "platform="
    _(request).must_include "type="
    _(request).must_include "statement="
  end

  it "image_build sends POST /build with every documented parameter" do
    request = wire(200) do |operations|
      operations.image_build(
        dockerfile: "sample",
        t: "sample",
        extrahosts: "sample",
        remote: "sample",
        q: true,
        nocache: true,
        cachefrom: "sample",
        pull: "sample",
        rm: true,
        forcerm: true,
        memory: 1,
        memswap: 1,
        cpushares: 1,
        cpusetcpus: "sample",
        cpuperiod: 1,
        cpuquota: 1,
        buildargs: "sample",
        shmsize: 1,
        squash: true,
        labels: "sample",
        networkmode: "sample",
        platform: "sample",
        target: "sample",
        outputs: "sample",
        version: "sample",
        content_type: "sample",
        x_registry_config: "sample",
        body: { "sample" => "body" }
      )
    end

    _(request).must_include "POST /v1.55/build"
    _(request).must_include "dockerfile="
    _(request).must_include "t="
    _(request).must_include "extrahosts="
    _(request).must_include "remote="
    _(request).must_include "q="
    _(request).must_include "nocache="
    _(request).must_include "cachefrom="
    _(request).must_include "pull="
    _(request).must_include "rm="
    _(request).must_include "forcerm="
    _(request).must_include "memory="
    _(request).must_include "memswap="
    _(request).must_include "cpushares="
    _(request).must_include "cpusetcpus="
    _(request).must_include "cpuperiod="
    _(request).must_include "cpuquota="
    _(request).must_include "buildargs="
    _(request).must_include "shmsize="
    _(request).must_include "squash="
    _(request).must_include "labels="
    _(request).must_include "networkmode="
    _(request).must_include "platform="
    _(request).must_include "target="
    _(request).must_include "outputs="
    _(request).must_include "version="
    _(request.downcase).must_include "content-type: "
    _(request.downcase).must_include "x-registry-config: "
  end

  it "image_commit sends POST /commit with every documented parameter" do
    request = wire(201) do |operations|
      operations.image_commit(
        container: "sample",
        repo: "sample",
        tag: "sample",
        comment: "sample",
        author: "sample",
        pause: true,
        changes: "sample",
        body: { "sample" => "body" }
      )
    end

    _(request).must_include "POST /v1.55/commit"
    _(request).must_include "container="
    _(request).must_include "repo="
    _(request).must_include "tag="
    _(request).must_include "comment="
    _(request).must_include "author="
    _(request).must_include "pause="
    _(request).must_include "changes="
  end

  it "image_create sends POST /images/create with every documented parameter" do
    request = wire(200) do |operations|
      operations.image_create(
        from_image: "sample",
        from_src: "sample",
        repo: "sample",
        tag: "sample",
        message: "sample",
        changes: ["sample"],
        platform: "sample",
        x_registry_auth: "sample",
        body: { "sample" => "body" }
      )
    end

    _(request).must_include "POST /v1.55/images/create"
    _(request).must_include "fromImage="
    _(request).must_include "fromSrc="
    _(request).must_include "repo="
    _(request).must_include "tag="
    _(request).must_include "message="
    _(request).must_include "changes="
    _(request).must_include "platform="
    _(request.downcase).must_include "x-registry-auth: "
  end

  it "image_delete sends DELETE /images/{name} with every documented parameter" do
    request = wire(200) do |operations|
      operations.image_delete(
        name: "sample-name",
        force: true,
        noprune: true,
        platforms: ["sample"]
      )
    end

    _(request).must_include "DELETE /v1.55/images/sample-name"
    _(request).must_include "force="
    _(request).must_include "noprune="
    _(request).must_include "platforms="
  end

  it "image_get sends GET /images/{name}/get with every documented parameter" do
    request = wire(200) do |operations|
      operations.image_get(
        name: "sample-name",
        platform: ["sample"]
      )
    end

    _(request).must_include "GET /v1.55/images/sample-name/get"
    _(request).must_include "platform="
  end

  it "image_get_all sends GET /images/get with every documented parameter" do
    request = wire(200) do |operations|
      operations.image_get_all(
        names: ["sample"],
        platform: ["sample"]
      )
    end

    _(request).must_include "GET /v1.55/images/get"
    _(request).must_include "names="
    _(request).must_include "platform="
  end

  it "image_history sends GET /images/{name}/history with every documented parameter" do
    request = wire(200) do |operations|
      operations.image_history(
        name: "sample-name",
        platform: "sample"
      )
    end

    _(request).must_include "GET /v1.55/images/sample-name/history"
    _(request).must_include "platform="
  end

  it "image_inspect sends GET /images/{name}/json with every documented parameter" do
    request = wire(200) do |operations|
      operations.image_inspect(
        name: "sample-name",
        manifests: true,
        platform: "sample"
      )
    end

    _(request).must_include "GET /v1.55/images/sample-name/json"
    _(request).must_include "manifests="
    _(request).must_include "platform="
  end

  it "image_list sends GET /images/json with every documented parameter" do
    request = wire(200) do |operations|
      operations.image_list(
        all: true,
        filters: "sample",
        shared_size: true,
        digests: true,
        manifests: true,
        identity: true
      )
    end

    _(request).must_include "GET /v1.55/images/json"
    _(request).must_include "all="
    _(request).must_include "filters="
    _(request).must_include "shared-size="
    _(request).must_include "digests="
    _(request).must_include "manifests="
    _(request).must_include "identity="
  end

  it "image_load sends POST /images/load with every documented parameter" do
    request = wire(200) do |operations|
      operations.image_load(
        quiet: true,
        platform: ["sample"],
        body: { "sample" => "body" }
      )
    end

    _(request).must_include "POST /v1.55/images/load"
    _(request).must_include "quiet="
    _(request).must_include "platform="
  end

  it "image_prune sends POST /images/prune with every documented parameter" do
    request = wire(200) do |operations|
      operations.image_prune(
        filters: "sample"
      )
    end

    _(request).must_include "POST /v1.55/images/prune"
    _(request).must_include "filters="
  end

  it "image_push sends POST /images/{name}/push with every documented parameter" do
    request = wire(200) do |operations|
      operations.image_push(
        name: "sample-name",
        x_registry_auth: "sample",
        tag: "sample",
        platform: "sample"
      )
    end

    _(request).must_include "POST /v1.55/images/sample-name/push"
    _(request).must_include "tag="
    _(request).must_include "platform="
    _(request.downcase).must_include "x-registry-auth: "
  end

  it "image_search sends GET /images/search with every documented parameter" do
    request = wire(200) do |operations|
      operations.image_search(
        term: "sample",
        limit: 1,
        filters: "sample"
      )
    end

    _(request).must_include "GET /v1.55/images/search"
    _(request).must_include "term="
    _(request).must_include "limit="
    _(request).must_include "filters="
  end

  it "image_tag sends POST /images/{name}/tag with every documented parameter" do
    request = wire(201) do |operations|
      operations.image_tag(
        name: "sample-name",
        repo: "sample",
        tag: "sample"
      )
    end

    _(request).must_include "POST /v1.55/images/sample-name/tag"
    _(request).must_include "repo="
    _(request).must_include "tag="
  end

  it "network_connect sends POST /networks/{id}/connect with every documented parameter" do
    request = wire(200) do |operations|
      operations.network_connect(
        id: "sample-id",
        body: { "sample" => "body" }
      )
    end

    _(request).must_include "POST /v1.55/networks/sample-id/connect"
  end

  it "network_create sends POST /networks/create with every documented parameter" do
    request = wire(201) do |operations|
      operations.network_create(
        body: { "sample" => "body" }
      )
    end

    _(request).must_include "POST /v1.55/networks/create"
  end

  it "network_delete sends DELETE /networks/{id} with every documented parameter" do
    request = wire(204) do |operations|
      operations.network_delete(
        id: "sample-id"
      )
    end

    _(request).must_include "DELETE /v1.55/networks/sample-id"
  end

  it "network_disconnect sends POST /networks/{id}/disconnect with every documented parameter" do
    request = wire(200) do |operations|
      operations.network_disconnect(
        id: "sample-id",
        body: { "sample" => "body" }
      )
    end

    _(request).must_include "POST /v1.55/networks/sample-id/disconnect"
  end

  it "network_inspect sends GET /networks/{id} with every documented parameter" do
    request = wire(200) do |operations|
      operations.network_inspect(
        id: "sample-id",
        verbose: true,
        scope: "sample"
      )
    end

    _(request).must_include "GET /v1.55/networks/sample-id"
    _(request).must_include "verbose="
    _(request).must_include "scope="
  end

  it "network_list sends GET /networks with every documented parameter" do
    request = wire(200) do |operations|
      operations.network_list(
        filters: "sample"
      )
    end

    _(request).must_include "GET /v1.55/networks"
    _(request).must_include "filters="
  end

  it "network_prune sends POST /networks/prune with every documented parameter" do
    request = wire(200) do |operations|
      operations.network_prune(
        filters: "sample"
      )
    end

    _(request).must_include "POST /v1.55/networks/prune"
    _(request).must_include "filters="
  end

  it "node_delete sends DELETE /nodes/{id} with every documented parameter" do
    request = wire(200) do |operations|
      operations.node_delete(
        id: "sample-id",
        force: true
      )
    end

    _(request).must_include "DELETE /v1.55/nodes/sample-id"
    _(request).must_include "force="
  end

  it "node_inspect sends GET /nodes/{id} with every documented parameter" do
    request = wire(200) do |operations|
      operations.node_inspect(
        id: "sample-id"
      )
    end

    _(request).must_include "GET /v1.55/nodes/sample-id"
  end

  it "node_list sends GET /nodes with every documented parameter" do
    request = wire(200) do |operations|
      operations.node_list(
        filters: "sample"
      )
    end

    _(request).must_include "GET /v1.55/nodes"
    _(request).must_include "filters="
  end

  it "node_update sends POST /nodes/{id}/update with every documented parameter" do
    request = wire(200) do |operations|
      operations.node_update(
        id: "sample-id",
        version: 1,
        body: { "sample" => "body" }
      )
    end

    _(request).must_include "POST /v1.55/nodes/sample-id/update"
    _(request).must_include "version="
  end

  it "get_plugin_privileges sends GET /plugins/privileges with every documented parameter" do
    request = wire(200) do |operations|
      operations.get_plugin_privileges(
        remote: "sample"
      )
    end

    _(request).must_include "GET /v1.55/plugins/privileges"
    _(request).must_include "remote="
  end

  it "plugin_create sends POST /plugins/create with every documented parameter" do
    request = wire(204) do |operations|
      operations.plugin_create(
        name: "sample",
        body: { "sample" => "body" }
      )
    end

    _(request).must_include "POST /v1.55/plugins/create"
    _(request).must_include "name="
  end

  it "plugin_delete sends DELETE /plugins/{name} with every documented parameter" do
    request = wire(200) do |operations|
      operations.plugin_delete(
        name: "sample-name",
        force: true
      )
    end

    _(request).must_include "DELETE /v1.55/plugins/sample-name"
    _(request).must_include "force="
  end

  it "plugin_disable sends POST /plugins/{name}/disable with every documented parameter" do
    request = wire(200) do |operations|
      operations.plugin_disable(
        name: "sample-name",
        force: true
      )
    end

    _(request).must_include "POST /v1.55/plugins/sample-name/disable"
    _(request).must_include "force="
  end

  it "plugin_enable sends POST /plugins/{name}/enable with every documented parameter" do
    request = wire(200) do |operations|
      operations.plugin_enable(
        name: "sample-name",
        timeout: 1
      )
    end

    _(request).must_include "POST /v1.55/plugins/sample-name/enable"
    _(request).must_include "timeout="
  end

  it "plugin_inspect sends GET /plugins/{name}/json with every documented parameter" do
    request = wire(200) do |operations|
      operations.plugin_inspect(
        name: "sample-name"
      )
    end

    _(request).must_include "GET /v1.55/plugins/sample-name/json"
  end

  it "plugin_list sends GET /plugins with every documented parameter" do
    request = wire(200) do |operations|
      operations.plugin_list(
        filters: "sample"
      )
    end

    _(request).must_include "GET /v1.55/plugins"
    _(request).must_include "filters="
  end

  it "plugin_pull sends POST /plugins/pull with every documented parameter" do
    request = wire(204) do |operations|
      operations.plugin_pull(
        remote: "sample",
        name: "sample",
        x_registry_auth: "sample",
        body: { "sample" => "body" }
      )
    end

    _(request).must_include "POST /v1.55/plugins/pull"
    _(request).must_include "remote="
    _(request).must_include "name="
    _(request.downcase).must_include "x-registry-auth: "
  end

  it "plugin_push sends POST /plugins/{name}/push with every documented parameter" do
    request = wire(200) do |operations|
      operations.plugin_push(
        name: "sample-name"
      )
    end

    _(request).must_include "POST /v1.55/plugins/sample-name/push"
  end

  it "plugin_set sends POST /plugins/{name}/set with every documented parameter" do
    request = wire(204) do |operations|
      operations.plugin_set(
        name: "sample-name",
        body: { "sample" => "body" }
      )
    end

    _(request).must_include "POST /v1.55/plugins/sample-name/set"
  end

  it "plugin_upgrade sends POST /plugins/{name}/upgrade with every documented parameter" do
    request = wire(204) do |operations|
      operations.plugin_upgrade(
        name: "sample-name",
        remote: "sample",
        x_registry_auth: "sample",
        body: { "sample" => "body" }
      )
    end

    _(request).must_include "POST /v1.55/plugins/sample-name/upgrade"
    _(request).must_include "remote="
    _(request.downcase).must_include "x-registry-auth: "
  end

  it "secret_create sends POST /secrets/create with every documented parameter" do
    request = wire(201) do |operations|
      operations.secret_create(
        body: { "sample" => "body" }
      )
    end

    _(request).must_include "POST /v1.55/secrets/create"
  end

  it "secret_delete sends DELETE /secrets/{id} with every documented parameter" do
    request = wire(204) do |operations|
      operations.secret_delete(
        id: "sample-id"
      )
    end

    _(request).must_include "DELETE /v1.55/secrets/sample-id"
  end

  it "secret_inspect sends GET /secrets/{id} with every documented parameter" do
    request = wire(200) do |operations|
      operations.secret_inspect(
        id: "sample-id"
      )
    end

    _(request).must_include "GET /v1.55/secrets/sample-id"
  end

  it "secret_list sends GET /secrets with every documented parameter" do
    request = wire(200) do |operations|
      operations.secret_list(
        filters: "sample"
      )
    end

    _(request).must_include "GET /v1.55/secrets"
    _(request).must_include "filters="
  end

  it "secret_update sends POST /secrets/{id}/update with every documented parameter" do
    request = wire(200) do |operations|
      operations.secret_update(
        id: "sample-id",
        version: 1,
        body: { "sample" => "body" }
      )
    end

    _(request).must_include "POST /v1.55/secrets/sample-id/update"
    _(request).must_include "version="
  end

  it "service_create sends POST /services/create with every documented parameter" do
    request = wire(201) do |operations|
      operations.service_create(
        body: { "sample" => "body" },
        x_registry_auth: "sample"
      )
    end

    _(request).must_include "POST /v1.55/services/create"
    _(request.downcase).must_include "x-registry-auth: "
  end

  it "service_delete sends DELETE /services/{id} with every documented parameter" do
    request = wire(200) do |operations|
      operations.service_delete(
        id: "sample-id"
      )
    end

    _(request).must_include "DELETE /v1.55/services/sample-id"
  end

  it "service_inspect sends GET /services/{id} with every documented parameter" do
    request = wire(200) do |operations|
      operations.service_inspect(
        id: "sample-id",
        insert_defaults: true
      )
    end

    _(request).must_include "GET /v1.55/services/sample-id"
    _(request).must_include "insertDefaults="
  end

  it "service_list sends GET /services with every documented parameter" do
    request = wire(200) do |operations|
      operations.service_list(
        filters: "sample",
        status: true
      )
    end

    _(request).must_include "GET /v1.55/services"
    _(request).must_include "filters="
    _(request).must_include "status="
  end

  it "service_logs sends GET /services/{id}/logs with every documented parameter" do
    request = wire(200) do |operations|
      operations.service_logs(
        id: "sample-id",
        details: true,
        follow: true,
        stdout: true,
        stderr: true,
        since: 1,
        timestamps: true,
        tail: "sample"
      )
    end

    _(request).must_include "GET /v1.55/services/sample-id/logs"
    _(request).must_include "details="
    _(request).must_include "follow="
    _(request).must_include "stdout="
    _(request).must_include "stderr="
    _(request).must_include "since="
    _(request).must_include "timestamps="
    _(request).must_include "tail="
  end

  it "service_update sends POST /services/{id}/update with every documented parameter" do
    request = wire(200) do |operations|
      operations.service_update(
        id: "sample-id",
        body: { "sample" => "body" },
        version: 1,
        registry_auth_from: "sample",
        rollback: "sample",
        x_registry_auth: "sample"
      )
    end

    _(request).must_include "POST /v1.55/services/sample-id/update"
    _(request).must_include "version="
    _(request).must_include "registryAuthFrom="
    _(request).must_include "rollback="
    _(request.downcase).must_include "x-registry-auth: "
  end

  it "session sends POST /session with every documented parameter" do
    request = wire(200) do |operations|
      operations.session

    end

    _(request).must_include "POST /v1.55/session"
  end

  it "swarm_init sends POST /swarm/init with every documented parameter" do
    request = wire(200) do |operations|
      operations.swarm_init(
        body: { "sample" => "body" }
      )
    end

    _(request).must_include "POST /v1.55/swarm/init"
  end

  it "swarm_inspect sends GET /swarm with every documented parameter" do
    request = wire(200) do |operations|
      operations.swarm_inspect

    end

    _(request).must_include "GET /v1.55/swarm"
  end

  it "swarm_join sends POST /swarm/join with every documented parameter" do
    request = wire(200) do |operations|
      operations.swarm_join(
        body: { "sample" => "body" }
      )
    end

    _(request).must_include "POST /v1.55/swarm/join"
  end

  it "swarm_leave sends POST /swarm/leave with every documented parameter" do
    request = wire(200) do |operations|
      operations.swarm_leave(
        force: true
      )
    end

    _(request).must_include "POST /v1.55/swarm/leave"
    _(request).must_include "force="
  end

  it "swarm_unlock sends POST /swarm/unlock with every documented parameter" do
    request = wire(200) do |operations|
      operations.swarm_unlock(
        body: { "sample" => "body" }
      )
    end

    _(request).must_include "POST /v1.55/swarm/unlock"
  end

  it "swarm_unlockkey sends GET /swarm/unlockkey with every documented parameter" do
    request = wire(200) do |operations|
      operations.swarm_unlockkey

    end

    _(request).must_include "GET /v1.55/swarm/unlockkey"
  end

  it "swarm_update sends POST /swarm/update with every documented parameter" do
    request = wire(200) do |operations|
      operations.swarm_update(
        body: { "sample" => "body" },
        version: 1,
        rotate_worker_token: true,
        rotate_manager_token: true,
        rotate_manager_unlock_key: true
      )
    end

    _(request).must_include "POST /v1.55/swarm/update"
    _(request).must_include "version="
    _(request).must_include "rotateWorkerToken="
    _(request).must_include "rotateManagerToken="
    _(request).must_include "rotateManagerUnlockKey="
  end

  it "system_auth sends POST /auth with every documented parameter" do
    request = wire(200) do |operations|
      operations.system_auth(
        body: { "sample" => "body" }
      )
    end

    _(request).must_include "POST /v1.55/auth"
  end

  it "system_data_usage sends GET /system/df with every documented parameter" do
    request = wire(200) do |operations|
      operations.system_data_usage(
        type: ["sample"],
        verbose: true
      )
    end

    _(request).must_include "GET /v1.55/system/df"
    _(request).must_include "type="
    _(request).must_include "verbose="
  end

  it "system_events sends GET /events with every documented parameter" do
    request = wire(200) do |operations|
      operations.system_events(
        since: "sample",
        until_: "sample",
        filters: "sample"
      )
    end

    _(request).must_include "GET /v1.55/events"
    _(request).must_include "since="
    _(request).must_include "until="
    _(request).must_include "filters="
  end

  it "system_info sends GET /info with every documented parameter" do
    request = wire(200) do |operations|
      operations.system_info

    end

    _(request).must_include "GET /v1.55/info"
  end

  it "system_ping sends GET /_ping with every documented parameter" do
    request = wire(200) do |operations|
      operations.system_ping

    end

    _(request).must_include "GET /_ping"
  end

  it "system_ping_head sends HEAD /_ping with every documented parameter" do
    request = wire(200) do |operations|
      operations.system_ping_head

    end

    _(request).must_include "HEAD /_ping"
  end

  it "system_version sends GET /version with every documented parameter" do
    request = wire(200) do |operations|
      operations.system_version

    end

    _(request).must_include "GET /v1.55/version"
  end

  it "task_inspect sends GET /tasks/{id} with every documented parameter" do
    request = wire(200) do |operations|
      operations.task_inspect(
        id: "sample-id"
      )
    end

    _(request).must_include "GET /v1.55/tasks/sample-id"
  end

  it "task_list sends GET /tasks with every documented parameter" do
    request = wire(200) do |operations|
      operations.task_list(
        filters: "sample"
      )
    end

    _(request).must_include "GET /v1.55/tasks"
    _(request).must_include "filters="
  end

  it "task_logs sends GET /tasks/{id}/logs with every documented parameter" do
    request = wire(200) do |operations|
      operations.task_logs(
        id: "sample-id",
        details: true,
        follow: true,
        stdout: true,
        stderr: true,
        since: 1,
        timestamps: true,
        tail: "sample"
      )
    end

    _(request).must_include "GET /v1.55/tasks/sample-id/logs"
    _(request).must_include "details="
    _(request).must_include "follow="
    _(request).must_include "stdout="
    _(request).must_include "stderr="
    _(request).must_include "since="
    _(request).must_include "timestamps="
    _(request).must_include "tail="
  end

  it "volume_create sends POST /volumes/create with every documented parameter" do
    request = wire(201) do |operations|
      operations.volume_create(
        body: { "sample" => "body" }
      )
    end

    _(request).must_include "POST /v1.55/volumes/create"
  end

  it "volume_delete sends DELETE /volumes/{name} with every documented parameter" do
    request = wire(204) do |operations|
      operations.volume_delete(
        name: "sample-name",
        force: true
      )
    end

    _(request).must_include "DELETE /v1.55/volumes/sample-name"
    _(request).must_include "force="
  end

  it "volume_inspect sends GET /volumes/{name} with every documented parameter" do
    request = wire(200) do |operations|
      operations.volume_inspect(
        name: "sample-name"
      )
    end

    _(request).must_include "GET /v1.55/volumes/sample-name"
  end

  it "volume_list sends GET /volumes with every documented parameter" do
    request = wire(200) do |operations|
      operations.volume_list(
        filters: "sample"
      )
    end

    _(request).must_include "GET /v1.55/volumes"
    _(request).must_include "filters="
  end

  it "volume_prune sends POST /volumes/prune with every documented parameter" do
    request = wire(200) do |operations|
      operations.volume_prune(
        filters: "sample"
      )
    end

    _(request).must_include "POST /v1.55/volumes/prune"
    _(request).must_include "filters="
  end

  it "volume_update sends PUT /volumes/{name} with every documented parameter" do
    request = wire(200) do |operations|
      operations.volume_update(
        name: "sample-name",
        version: 1,
        body: { "sample" => "body" }
      )
    end

    _(request).must_include "PUT /v1.55/volumes/sample-name"
    _(request).must_include "version="
  end
end
