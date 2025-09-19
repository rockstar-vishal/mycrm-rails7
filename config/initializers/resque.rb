require 'resque/scheduler'
require 'resque/scheduler/server'

# Configure Resque to use proper Rails autoloading
Rails.application.config.after_initialize do
  begin
    # Let Rails handle job loading automatically through Zeitwerk
    # This is more reliable than manual file loading
    Rails.logger.info "Resque jobs will be loaded automatically by Rails autoloader"
  rescue => e
    Rails.logger.warn "Warning: Could not configure Resque: #{e.message}"
  end
end

begin
  Resque.schedule = YAML.load_file("#{Rails.root}/config/resque_schedule.yml")
  puts "Resque scheduler loaded successfully"
rescue => e
  puts "Warning: Could not load Resque schedule: #{e.message}"
  puts "Background jobs will not be scheduled"
end