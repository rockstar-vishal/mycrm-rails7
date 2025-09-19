Koala.configure do |config|
  config.app_id = defined?(CRMConfig) ? CRMConfig.fb_app_id : ENV['FB_APP_ID']
  config.app_secret = defined?(CRMConfig) ? CRMConfig.fb_app_secret : ENV['FB_APP_SECRET']
  api_version = "v10.0"
  # See Koala::Configuration for more options, including details on how to send requests through
  # your own proxy servers.
end