require 'resque/server'

Resque::Server.use(Rack::Auth::Basic) do |username, password|
  password == (defined?(CRMConfig) ? CRMConfig.resque_password : ENV['RESQUE_PASSWORD'])
end