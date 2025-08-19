require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.enable_reloading = true

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true
  
  # Show detailed error pages
  config.action_dispatch.show_exceptions = true

  # Enable server timing
  config.server_timing = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise
  
  # Enhanced logging for development
  config.log_level = :debug
  config.logger = ActiveSupport::Logger.new(STDOUT)
  config.logger.formatter = proc do |severity, datetime, progname, msg|
    "#{datetime.strftime('%Y-%m-%d %H:%M:%S')} [#{severity}] #{msg}\n"
  end

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Highlight code that enqueued background job in logs.
  config.active_job.verbose_enqueue_logs = true
  
  # Use Resque for background jobs in development
  config.active_job.queue_adapter = :resque

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  # Configure the default encoding
  config.encoding = "utf-8"

  # Configure sensitive parameters which will be filtered from the log file.
  config.filter_parameters += [:password]

  # Enable escaping HTML in JSON.
  config.active_support.escape_html_entities_in_json = true

  # Version of your assets, change this if you want to expire all your assets
  config.assets.version = '1.0'

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  config.time_zone = 'Asia/Kolkata'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  config.i18n.default_locale = :en

  # Configure CORS
  config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins '*'
      resource '*', :headers => :any, :methods => [:get, :post, :options, :put, :patch, :delete]
    end
  end

  # Configure SMTP settings
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    :user_name => "AKIARRQ5JN5T54YDEF53",
    :password => "BLAemLncb7tr7WqJppih3+mKyILQe8EFipjierUHmVSa",
    :domain => "corelto.co",
    :address => "email-smtp.ap-south-1.amazonaws.com",
    :port => 25,
    :authentication => :plain,
    :enable_starttls_auto => true
  }
end
