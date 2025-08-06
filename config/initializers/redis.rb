require 'redis-namespace'

begin
  # Redis configuration for Rails 7.1
  redis_connection = Redis.new(
    host: CRMConfig.redis_host, 
    port: CRMConfig.redis_port
  )

  # Create a namespaced Redis connection for the application
  $redis = Redis::Namespace.new(:leadquest_corelto, redis: redis_connection)

  # Configure Resque to use the Redis connection
  Resque.redis = $redis
  
  puts "Redis connection established successfully"
rescue => e
  puts "Warning: Could not connect to Redis: #{e.message}"
  puts "Application will start without Redis functionality"
  $redis = nil
end