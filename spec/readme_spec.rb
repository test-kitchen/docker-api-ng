# frozen_string_literal: true

require "spec_helper"

# The README teaches Transport::Fake by showing raw HTTP bytes. Those bytes are
# the first thing a reader copies, so a fixture that declares the wrong
# Content-Length teaches a malformed daemon -- and it does not announce itself,
# because Net::HTTP accepts the short read when the fake hangs up.
describe "the README's Transport::Fake fixture" do
  def fixtures
    source = File.read(File.expand_path("../README.md", __dir__))
    source.scan(/Content-Length: (\d+)\\r\\n\\r\\n" \\\n\s*'([^']*)'/)
  end

  it "still contains a raw HTTP fixture to check" do
    _(fixtures).wont_be_empty
  end

  it "declares a Content-Length matching the body it ships with" do
    fixtures.each do |declared, body|
      _(declared.to_i).must_equal(
        body.bytesize,
        "README fixture declares Content-Length #{declared} for a #{body.bytesize}-byte body"
      )
    end
  end
end
