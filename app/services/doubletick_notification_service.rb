require 'uri'
require "net/http"
require 'json'

class DoubletickNotificationService
  class << self
    # Send WhatsApp template message via DoubleTick API
    # @param lead [Lead] The lead object
    # @param template_name [String] The name of the template to send
    # @param api_key [String] The DoubleTick API key
    # @return [Array] [success_boolean, response_message]
    def send_template_message(lead, template_name, api_key)
      begin
        # Format and validate phone number before making API call
        phone_number, validation_error = format_and_validate_phone_number(lead.mobile)
        
        if validation_error.present?
          return false, validation_error
        end
        
        url = URI.parse("https://public.doubletick.io/whatsapp/message/template")
        
        # DoubleTick API payload format - matches curl request structure
        payload = {
          messages: [
            {
              content: {
                language: "en",
                templateName: template_name
              },
              to: phone_number,
              from: "+918050771555"
            }
          ]
        }.to_json

        request = Net::HTTP::Post.new(url)
        request['Authorization'] = api_key
        request['accept'] = 'application/json'
        request['Content-Type'] = 'application/json'
        request.body = payload

        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        response = http.request(request)
        
        if response.is_a?(Net::HTTPSuccess)
          # Parse response to extract message ID
          begin
            response_data = JSON.parse(response.body)
            message_id = response_data.dig('messages', 0, 'messageId')
            return true, { body: response.body, message_id: message_id }
          rescue JSON::ParserError => e
            # If JSON parsing fails, return the raw body
            return true, { body: response.body, message_id: nil }
          end
        else
          return false, "Error: #{response.code} - #{response.message} - #{response.body}"
        end
      rescue => e
        return false, e.message
      end
    end

    private

    # Format phone number and validate it's exactly 10 digits (without country code)
    # @param mobile [String] The mobile number
    # @return [Array] [formatted_phone_number, validation_error]
    def format_and_validate_phone_number(mobile)
      # Remove any spaces
      cleaned = mobile.to_s.gsub(/\s+/, '')
      
      # Extract the 10-digit number (remove country code if present)
      if cleaned.start_with?('91') && cleaned.length == 12
        # Number starts with 91 and is 12 digits total (91 + 10 digits)
        digits_only = cleaned[2..-1]
      elsif cleaned.length == 10
        # Number is exactly 10 digits
        digits_only = cleaned
      elsif cleaned.start_with?('+91') && cleaned.length == 13
        # Number starts with +91 and is 13 characters total (+91 + 10 digits)
        digits_only = cleaned[3..-1]
      else
        # Invalid format
        return nil, "Invalid phone number: must be exactly 10 digits (without country code). Received: #{mobile}"
      end
      
      # Validate it's exactly 10 digits and all numeric
      unless digits_only.length == 10 && digits_only.match?(/^\d{10}$/)
        return nil, "Invalid phone number: must be exactly 10 digits (without country code). Received: #{mobile}"
      end
      
      # Format as +91XXXXXXXXXX
      formatted = "+91#{digits_only}"
      return formatted, nil
    end
  end
end

