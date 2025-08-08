# Paperclip S3 configuration
# This file configures Paperclip to use S3 storage if AWS credentials are available

if Rails.application.credentials.dig(:aws, :access_key_id).present? || ENV['AWS_ACCESS_KEY_ID'].present?
  # Configure Paperclip to use S3 storage
  Paperclip::Attachment.default_options.update({
    storage: :s3,
    s3_credentials: {
      access_key_id: Rails.application.credentials.dig(:aws, :access_key_id) || ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: Rails.application.credentials.dig(:aws, :secret_access_key) || ENV['AWS_SECRET_ACCESS_KEY'],
      region: Rails.application.credentials.dig(:aws, :region) || ENV['AWS_REGION'] || 'ap-south-1'
    },
    s3_region: Rails.application.credentials.dig(:aws, :region) || ENV['AWS_REGION'] || 'ap-south-1',
    bucket: Rails.application.credentials.dig(:aws, :bucket_name) || ENV['AWS_BUCKET_NAME'],
    s3_host_alias: nil,
    url: ':s3_domain_url',
    path: ':class/:attachment/:id/:style/:filename',
    s3_protocol: 'https',
    escape_url: false
  })
  
  # Override the default options to ensure S3 is used
  Paperclip::Attachment.default_options[:storage] = :s3
  Paperclip::Attachment.default_options[:s3_credentials] = {
    access_key_id: Rails.application.credentials.dig(:aws, :access_key_id) || ENV['AWS_ACCESS_KEY_ID'],
    secret_access_key: Rails.application.credentials.dig(:aws, :secret_access_key) || ENV['AWS_SECRET_ACCESS_KEY'],
    region: Rails.application.credentials.dig(:aws, :region) || ENV['AWS_REGION'] || 'ap-south-1'
  }
  Paperclip::Attachment.default_options[:s3_region] = Rails.application.credentials.dig(:aws, :region) || ENV['AWS_REGION'] || 'ap-south-1'
  Paperclip::Attachment.default_options[:bucket] = Rails.application.credentials.dig(:aws, :bucket_name) || ENV['AWS_BUCKET_NAME']
  Paperclip::Attachment.default_options[:url] = ':s3_domain_url'
  Paperclip::Attachment.default_options[:path] = ':class/:attachment/:id/:style/:filename'
  Paperclip::Attachment.default_options[:s3_protocol] = 'https'
  Paperclip::Attachment.default_options[:escape_url] = false
  
  puts "Paperclip configured to use S3 storage"
else
  # Use local storage if no S3 credentials are configured
  Paperclip::Attachment.default_options.update({
    storage: :filesystem,
    path: ":rails_root/public/system/:attachment/:id/:style/:filename",
    url: "/system/:attachment/:id/:style/:filename"
  })
  puts "Paperclip configured to use local filesystem storage"
end
