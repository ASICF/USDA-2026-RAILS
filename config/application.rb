require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Nrisli
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # config.active_job.queue_adapter = :delayed_job
    # Delayed::Worker.delay_jobs = false if Rails.env.development?

    config.action_mailer.default_url_options = { host: Rails.application.secrets.host }
    if Rails.application.secrets.smtp_settings
      config.action_mailer.delivery_method = :smtp
      config.action_mailer.smtp_settings = Rails.application.secrets.smtp_settings
    end
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
