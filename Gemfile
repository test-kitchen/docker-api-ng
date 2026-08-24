# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :test do
  gem "minitest", "~> 5.20"
  gem "mocha", "~> 3.0"
  gem "rake", ">= 13.0"
  gem "simplecov", require: false # opt-in via COVERAGE=1
end

group :development do
  gem "pry"
  gem "yard"
end

group :cookstyle do
  gem "cookstyle"
end

group :types do
  gem "rbs", "~> 3.4"
  gem "steep", "~> 1.6"
end
