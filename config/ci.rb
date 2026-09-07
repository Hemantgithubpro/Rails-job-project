# CI configuration for Rails
# This file is used by the CI pipeline.

# Database configuration for CI
ENV["RAILS_ENV"] = "test"
ENV["DB_NAME_TEST"] ||= "ecommerce_test"
