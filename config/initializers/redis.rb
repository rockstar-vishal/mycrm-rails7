require 'redis'
require 'redis-namespace'

redis_config = {
  host: defined?(CRMConfig) ? CRMConfig.redis_host : ENV['REDIS_HOST'] || 'localhost',
  port: defined?(CRMConfig) ? CRMConfig.redis_port : ENV['REDIS_PORT'] || 6379,
  db: defined?(CRMConfig) ? CRMConfig.redis_db : ENV['REDIS_DB'] || 0
}

namespace_tag = CRMConfig.redis_namespace || "leadquest"

redis_config[:password] = defined?(CRMConfig) ? CRMConfig.redis_password : ENV['REDIS_PASSWORD'] if defined?(CRMConfig) ? CRMConfig.redis_password.present? : ENV['REDIS_PASSWORD'].present?

$redis = Redis.new(redis_config)
$redis_ns = Redis::Namespace.new("#{namespace_tag}:#{Rails.env}", redis: $redis)

# Configure Resque to use the Redis connection
Resque.redis = $redis_ns
begin  
  puts "Redis connection established successfully"
rescue => e
  puts "Warning: Could not connect to Redis: #{e.message}"
  puts "Application will start without Redis functionality"
  $redis = nil
end