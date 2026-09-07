require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false

  # Turn on Action Controller caching.
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in ENV["RAILS_MASTER_KEY"], config/credentials.yml.enc, or config/master.key.
  config.require_master_key = true

  # Disable serving static files from the `/public` folder by default.
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # Enable Action Dispatch's `cache_control` middleware.
  config.action_dispatch.default_headers = {
    "Cache-Control" => "no-cache, no-store"
  }

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  config.assume_ssl = true

  # Force all access to the app over SSL.
  config.force_ssl = true

  # Skip http-to-https redirect for the health check endpoint.
  config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT for Docker/container environments.
  config.logger = ActiveSupport::Logger.new($stdout)
    .tap { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # Change to "debug" to log everything (including potentially personally-identifiable information).
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id in inspections for logs and inspections.
  config.active_record.attributes_for_inspect = [ :id ]

  # Enable DNS rebinding and other `Host` header attacks protection.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
