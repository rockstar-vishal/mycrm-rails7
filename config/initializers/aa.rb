# Initialize CRMConfig for Figaro environment variables
# Using a more robust approach to avoid circular dependencies
unless defined?(CRMConfig)
  begin
    require 'figaro'
    CRMConfig = Figaro.env
  rescue LoadError, NameError => e
    # Fallback to ENV if Figaro is not available
    CRMConfig = OpenStruct.new(ENV)
    if defined?(Rails) && Rails.logger
      Rails.logger.warn "CRMConfig initialization warning: #{e.message}"
    end
  end
end