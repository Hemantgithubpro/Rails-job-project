# frozen_string_literal: true

source "https://rubygems.org"

ruby ">= 3.3.0"

# Rails framework
gem "rails", "~> 8.1.0"

# PostgreSQL adapter
gem "pg", "~> 1.1"

# Web server
gem "puma", ">= 5.0"

# JSON serialization
gem "jbuilder"

# CORS support
gem "rack-cors"

# Bootsnap for faster boot times
gem "bootsnap", require: false

# Use Redis adapter to run Action Cable in production
# gem "redis", ">= 4.0.1"

# Use Kredis for higher-level data types
# gem "kredis"

# Use Active Model has_secure_password
gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching
# gem "bootsnap", require: false

# Use Active Storage variants
# gem "image_processing", "~> 1.2"

# Fix for Ruby 3.3+ net-imap/net-smtp circular dependency
gem "net-imap", ">= 0.4.14", require: false
gem "net-smtp", require: false

group :development, :test do
  gem "debug", require: "debug/prelude"
  gem "rspec-rails", "~> 6.0"
  gem "factory_bot_rails"
  gem "faker"
  gem "brakeman", require: false
  gem "bundler-audit", require: false
end

group :development do
  gem "rubocop-rails-omakase", require: false
  gem "annotate"
end

group :test do
  gem "shoulda-matchers", "~> 6.0"
end
