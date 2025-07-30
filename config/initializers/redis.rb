require 'redis-namespace'
redis_connection = Redis.new(:host => CRMConfig.redis_host, :port => CRMConfig.redis_port, :thread_safe => true)
Redis.current = Redis::Namespace.new(:leadquest_corelto, :redis => redis_connection)

Resque.redis = Redis.current