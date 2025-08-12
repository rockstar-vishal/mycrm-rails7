# Paperclip S3 configuration
# This file configures Paperclip to use S3 storage if AWS credentials are available

if Rails.application.credentials.dig(:aws, :access_key_id).present? || ENV['AWS_ACCESS_KEY_ID'].present?
  # Configure Paperclip to use S3 storage
  Paperclip::Attachment.default_options.merge!({
    storage: :s3,
    s3_credentials: {
      access_key_id: Rails.application.credentials.dig(:aws, :access_key_id) || ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: Rails.application.credentials.dig(:aws, :secret_access_key) || ENV['AWS_SECRET_ACCESS_KEY'],
      region: Rails.application.credentials.dig(:aws, :region) || ENV['AWS_REGION'] || 'ap-south-1'
    },
    s3_region: Rails.application.credentials.dig(:aws, :region) || ENV['AWS_REGION'] || 'ap-south-1',
    bucket: Rails.application.credentials.dig(:aws, :bucket_name) || ENV['AWS_BUCKET_NAME'],
    s3_host_alias: nil,
    url: ':s3_path_url',
    path: ':attachment/:id/:style/:filename',
    s3_protocol: 'https',
    escape_url: false,
    s3_host_name: 's3.ap-south-1.amazonaws.com'
  })
  
  puts "Paperclip configured to use S3 storage"
else
  # Use local storage if no S3 credentials are configured
  Paperclip::Attachment.default_options.merge!({
    storage: :filesystem,
    path: ":rails_root/public/system/:attachment/:id/:style/:filename",
    url: "/system/:attachment/:id/:style/:filename"
  })
  puts "Paperclip configured to use local filesystem storage"
end
