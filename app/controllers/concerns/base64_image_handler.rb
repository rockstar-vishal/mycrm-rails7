module Base64ImageHandler
  extend ActiveSupport::Concern

  private

  def convert_base64_to_file(base64_data_uri)
    # Extract the content type and base64 data from the data URI
    # Format: data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEBLAEsAAD...
    match = base64_data_uri.match(/^data:([^;]+);base64,(.+)$/)
    return nil unless match
    
    content_type = match[1]
    base64_data = match[2]
    
    # Decode the base64 data
    decoded_data = Base64.decode64(base64_data)
    
    # Determine file extension from content type
    extension = case content_type
               when 'image/jpeg', 'image/jpg'
                 '.jpg'
               when 'image/png'
                 '.png'
               when 'image/gif'
                 '.gif'
               else
                 '.jpg' # default to jpg
               end
    
    # Create a temporary file
    temp_file = Tempfile.new(['image', extension])
    temp_file.binmode
    temp_file.write(decoded_data)
    temp_file.rewind
    
    # Return a file object that Paperclip can handle
    ActionDispatch::Http::UploadedFile.new(
      tempfile: temp_file,
      filename: "image#{extension}",
      type: content_type
    )
  rescue => e
    Rails.logger.error "Error converting base64 image: #{e.message}"
    nil
  end

  def process_base64_image_param(params_data, param_name = :image)
    if params_data[param_name].present? && 
       params_data[param_name].is_a?(String) && 
       params_data[param_name].start_with?('data:image')
      params_data[param_name] = convert_base64_to_file(params_data[param_name])
    end
    params_data
  end
end
