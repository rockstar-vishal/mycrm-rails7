require 'resque/scheduler'
require 'resque/scheduler/server'

# Defer job loading until after Rails is fully initialized to avoid circular dependencies
Rails.application.config.after_initialize do
  begin
    # Only load job files if Rails is fully initialized and we're not in a problematic state
    if defined?(Rails) && Rails.application && !defined?(Rails::Console)
      Dir["#{Rails.root}/app/jobs/*.rb"].each do |file|
        begin
          require file
        rescue => e
          Rails.logger.warn "Warning: Could not load job file #{file}: #{e.message}" if defined?(Rails) && Rails.logger
        end
      end
    end
  rescue => e
    Rails.logger.warn "Warning: Could not load job files: #{e.message}" if defined?(Rails) && Rails.logger
  end
end

begin
  Resque.schedule = YAML.load_file("#{Rails.root}/config/resque_schedule.yml")
  puts "Resque scheduler loaded successfully"
rescue => e
  puts "Warning: Could not load Resque schedule: #{e.message}"
  puts "Background jobs will not be scheduled"
end