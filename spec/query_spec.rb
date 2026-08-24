# frozen_string_literal: true

require "spec_helper"

describe Docker::API::Query do
  it "returns an empty string when nothing survives, so callers can concatenate" do
    _(Docker::API::Query.encode(name: nil, platform: nil)).must_equal ""
    _(Docker::API::Query.encode({})).must_equal ""
    _(Docker::API::Query.encode(nil)).must_equal ""
  end

  # An empty value is not the same as an absent one: "?all=" is a parse error
  # to the daemon where omitting `all` is a documented default.
  it "drops nils rather than sending them empty" do
    _(Docker::API::Query.encode(all: true, limit: nil)).must_equal "?all=true"
  end

  it "renders booleans as the literal strings the daemon expects" do
    _(Docker::API::Query.encode(all: true, size: false)).must_equal "?all=true&size=false"
  end

  it "keeps false, which is meaningfully different from absent" do
    _(Docker::API::Query.encode(size: false)).must_include "size=false"
  end

  it "JSON-encodes a hash, because filters is declared as a string of JSON" do
    encoded = Docker::API::Query.encode(filters: { "status" => ["running"] })
    _(CGI.unescape(encoded)).must_equal '?filters={"status":["running"]}'
  end

  # The `platform` and `type` parameters of the image and system endpoints are
  # declared as arrays with collectionFormat: multi.
  it "repeats an array parameter rather than JSON-encoding it" do
    encoded = Docker::API::Query.encode(platform: ["linux/amd64", "linux/arm64"])
    _(CGI.unescape(encoded)).must_equal "?platform=linux/amd64&platform=linux/arm64"
  end

  it "escapes values that would otherwise break the URL" do
    _(Docker::API::Query.encode(name: "a b&c")).must_equal "?name=a+b%26c"
  end

  it "renders integers" do
    _(Docker::API::Query.encode(limit: 5)).must_equal "?limit=5"
  end
end
