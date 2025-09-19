# Sentry configuration for error tracking
# Temporarily disabled to avoid circular dependency issues with Rails 7.1 + Ruby 3.4

# if Rails.env.production?
#   begin
#     require 'resque/failure/multiple'
#     require 'resque/failure/redis'
#     
#     # Only load resque-sentry if it's available and not causing issues
#     begin
#       require 'resque-sentry'
#       Resque::Failure::Sentry.logger = "resque"
#       Resque::Failure::Multiple.classes = [Resque::Failure::Redis, Resque::Failure::Sentry]
#       Resque::Failure.backend = Resque::Failure::Multiple
#     rescue LoadError => e
#       # If resque-sentry is not available, just use Redis
#       Resque::Failure::Multiple.classes = [Resque::Failure::Redis]
#       Resque::Failure.backend = Resque::Failure::Multiple
#     end
#
#     Sentry.init do |config|
#       config.dsn = defined?(CRMConfig) ? CRMConfig.SENTRY_DSN : ENV['SENTRY_DSN']
#       config.breadcrumbs_logger = [:active_support_logger, :http_logger]
#       config.traces_sample_rate = 0.5
#     end
#   rescue => e
#     puts "Warning: Could not initialize Sentry: #{e.message}"
#   end
# end
