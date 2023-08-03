require_relative './common.rb'
require "active_support/core_ext/integer/time"

# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  # config.cache_store = :null_store

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = true

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection    = true

  config.action_controller.action_on_unpermitted_parameters = :raise

  # Store uploaded files on the local file system in a temporary directory
  config.active_storage.service = APP_CONFIG.active_storage_service.to_sym

  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # As instructed by Devise, to make local mails work
  config.action_mailer.default_url_options = { :host => 'test.lvh.me:9887' }

  ENV['RAILS_ASSET_ID'] = ""

  # Configure static asset server for tests with Cache-Control for performance
  config.static_cache_control = "public, max-age=3600"

  config.cache_store = :memory_store, { :namespace => "sharetribe-test"}

  config.active_support.test_order = :random
  config.active_support.deprecation = :stderr

  # We don't need schema dumps in this environment
  config.active_record.dump_schema_after_migration = false

  # Raises error for missing translations
  config.i18n.raise_on_missing_translations = false
  # ActiveStorage::Current.host = 'test.lvh.me:9887'

  # List of classes deemed safe to be deserialized from YAML.
  config.active_record.yaml_column_permitted_classes = [Symbol, ActiveSupport::HashWithIndifferentAccess]
end
