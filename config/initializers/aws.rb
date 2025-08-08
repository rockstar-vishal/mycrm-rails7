# AWS SDK v3 configuration for Paperclip compatibility
# The new AWS SDK v3 is configured through environment variables or credentials file

# Required for Paperclip compatibility with aws-sdk-s3
if Rails.application.credentials.dig(:aws, :access_key_id).present?
  Aws.config.update({
    region: Rails.application.credentials.dig(:aws, :region) || 'us-east-1',
    credentials: Aws::Credentials.new(
      Rails.application.credentials.dig(:aws, :access_key_id),
      Rails.application.credentials.dig(:aws, :secret_access_key)
    )
  })
end

# Paperclip S3 configuration for aws-sdk-s3 compatibility
Paperclip::Attachment.default_options[:s3_region] = Rails.application.credentials.dig(:aws, :region) || 'us-east-1'