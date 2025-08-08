# Configure Zeitwerk to ignore jobs directory since these are Resque jobs, not ActiveJob classes
Rails.autoloaders.main.ignore("#{Rails.root}/app/jobs")
