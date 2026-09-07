# This file is copied to spec/ when you run rails generate rspec:install
require "spec_helper"
ENV["RAILS_ENV"] = "test"
require_relative "../config/environment"

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

# Add additional requires below this line.
require "rspec/rails"
require "shoulda-matchers"

# Requires supporting ruby files with custom matchers and methods, etc.
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [Rails.root.join("spec/fixtures").to_s]

  # Use transactional tests for speed.
  config.use_transactional_fixtures = true

  # You can use this to use a different strategy for cleaning the database.
  # config.use_transactional_tests = true

  # Factory Bot methods
  config.include FactoryBot::Syntax::Methods

  # Automatically infer spec type from file location.
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!

  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
end

# Configure shoulda-matchers
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
