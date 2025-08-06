require 'resque/scheduler'
require 'resque/scheduler/server'
Dir["#{Rails.root}/app/jobs/*.rb"].each { |file| require file }

begin
  Resque.schedule = YAML.load_file("#{Rails.root}/config/resque_schedule.yml")
  puts "Resque scheduler loaded successfully"
rescue => e
  puts "Warning: Could not load Resque schedule: #{e.message}"
  puts "Background jobs will not be scheduled"
end