source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.4.1'

# Rails 7.1
gem 'rails', '~> 7.1.0'
gem 'bootsnap', require: false
gem 'puma', '~> 6.0'

# Database
gem 'pg', '~> 1.5'

# Asset pipeline for Rails 7
gem 'sprockets-rails'
gem 'importmap-rails'
gem 'turbo-rails'
gem 'stimulus-rails'

# JavaScript and CSS
gem 'sassc-rails'
gem 'uglifier', '>= 1.3.0'

# jQuery and Bootstrap
gem 'jquery-rails'
gem 'bootstrap', '~> 5.3'
gem 'bootstrap_form', '~> 5.2'

# Authentication
gem 'devise', '~> 4.9'

# File uploads (replacing Paperclip)
gem 'image_processing', '~> 1.2'

# Background jobs
gem 'resque', '~> 2.7'
gem 'resque-scheduler', '~> 4.1'

# Search
gem 'elasticsearch-model'
gem 'elasticsearch-rails'

# Core utilities
gem 'gon'
gem 'time_difference'
gem 'audited', '~> 5.0'
gem 'telephone_number', '~> 1.4'
gem 'acts_as_api', '~> 1.0'
gem 'workflow'
gem 'rack-cors'
gem 'rest-client', '~> 2.1'
gem 'will_paginate', '~> 3.1'
gem 'chartkick', '~> 5.0'
gem 'redis', '~> 5.0'
gem 'redis-namespace', '~> 1.8'
gem 'geocoder', '~> 1.8'
gem 'pusher'
gem 'haml', '~> 6.0'
gem 'momentjs-rails', '~> 2.29'
gem 'wicked_pdf', '~> 2.8'
gem 'wkhtmltopdf-binary'
gem 'with_advisory_lock', '~> 4.0'
gem 'liquid_markdown', '~> 0.2'

# AWS SDK v3 (replacing v1)
gem 'aws-sdk-s3', require: false

# Additional gems (simplified)
gem 'pushpad', '~> 1.3'
gem 'request_store', '~> 1.5'
gem 'koala', '~> 3.0'
gem 'mini_racer'
gem 'clipboard-rails'
gem 'bson_ext'
gem 'tilt', '~> 2.0'
gem 'httpclient'
gem 'cocoon'
gem 'font-awesome-rails'
gem 'chosen-rails'
gem 'cancan', '~> 1.6'
gem 'figaro'
gem 'jquery-tablesorter'
gem 'icheck-rails', '~> 1.0'
gem 'data-confirm-modal', '~> 1.2'
gem 'underscore-rails'
gem 'gmaps4rails'
gem 'jquery-datatables-rails', '~> 3.3'
gem 'carrierwave'
gem 'fullcalendar-rails', '~> 2.1'

group :development do
  gem 'listen', '~> 3.3'
end

group :production do
  gem 'zip'
  gem 'sentry-ruby', '~> 5.0'
  gem 'resque-sentry'
end

group :test, :development do
  gem 'bullet'
  gem 'byebug', '~> 11.0'
end
