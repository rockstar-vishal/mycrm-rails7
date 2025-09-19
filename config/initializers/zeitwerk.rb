# Configure Zeitwerk to properly load Resque jobs
# This allows Rails to autoload the job classes when they're referenced
Rails.autoloaders.main.push_dir("#{Rails.root}/app/jobs")
