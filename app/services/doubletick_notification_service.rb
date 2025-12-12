require 'uri'
require "net/http"

class DoubletickNotificationService
  class << self
    # Send WhatsApp template message via DoubleTick API
    # @param lead [Lead] The lead object
    # @param template_name [String] The name of the template to send
    # @param api_key [String] The DoubleTick API key
    # @return [Array] [success_boolean, response_message]
    def send_template_message(lead, template_name, api_key)
      begin
        url = URI.parse("https://public.doubletick.io/whatsapp/message/template")
        
        # Format phone number: ensure it starts with country code
        phone_number = format_phone_number(lead.mobile)
        
        # DoubleTick API payload format - matches curl request structure
        payload = {
          messages: [
            {
              content: {
                language: "en",
                templateName: template_name
              },
              to: phone_number
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
          return true, response.body
        else
          return false, "Error: #{response.code} - #{response.message} - #{response.body}"
        end
      rescue => e
        return false, e.message
      end
    end

    private

    def format_phone_number(mobile)
      # Remove any spaces and ensure it starts with country code
      cleaned = mobile.to_s.gsub(/\s+/, '')
      
      # If it doesn't start with country code, add 91 (India)
      if cleaned.start_with?('91')
        "+#{cleaned}"
      elsif cleaned.length == 10
        "+91#{cleaned}"
      else
        "+#{cleaned}"
      end
    end
  end
end

