require 'pusher'

Pusher.app_id = defined?(CRMConfig) ? CRMConfig.pusher_app_id : ENV['PUSHER_APP_ID']
Pusher.key = defined?(CRMConfig) ? CRMConfig.pusher_key : ENV['PUSHER_KEY']
Pusher.secret = defined?(CRMConfig) ? CRMConfig.pusher_secret : ENV['PUSHER_SECRET']
Pusher.cluster = defined?(CRMConfig) ? CRMConfig.pusher_cluster : ENV['PUSHER_CLUSTER']
Pusher.logger = Rails.logger
Pusher.encrypted = true