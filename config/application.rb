require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module EcommerceApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific files using `config/environments/*`.
    #
    # Common options:
    #   - config.time_zone = "Central Time (US & Canada)"
    #   - config.eager_load_paths << Rails.root.join("extras")

    # Only load the middleware you need. API-only app.
    config.api_only = true

    # Use Sidekiq or Solid Queue for background jobs in production
    # config.active_job.queue_adapter = :solid_queue

    # Time zone
    config.time_zone = "UTC"

    # Log to STDOUT in production/Docker
    if ENV["RAILS_LOG_TO_STDOUT"].present? || Rails.env.production?
      logger           = ActiveSupport::Logger.new($stdout)
      logger.formatter = config.log_formatter
      config.logger    = ActiveSupport::TaggedLogging.new(logger)
    end
  end
end
