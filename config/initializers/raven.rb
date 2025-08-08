# Sentry configuration for error tracking
# Updated to use sentry-ruby instead of deprecated sentry-raven

if Rails.env.production?
  require 'resque/failure/multiple'
  require 'resque/failure/redis'
  require 'resque-sentry'

  Resque::Failure::Sentry.logger = "resque"
  Resque::Failure::Multiple.classes = [Resque::Failure::Redis, Resque::Failure::Sentry]
  Resque::Failure.backend = Resque::Failure::Multiple

  Sentry.init do |config|
    config.dsn = CRMConfig.SENTRY_DSN
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]
    config.traces_sample_rate = 0.5
  end
end
