class ProcessAshpuraSms
    require 'uri'
    require 'net/http'
    require 'json'
  
    @queue = :process_ashpura_sms
    @process_ashpura_sms_logger = Logger.new('log/process_ashpura_sms.log')
  
    def self.perform id
      sms = ::SystemSms.find(id)
     
      begin
        @process_ashpura_sms_logger.info("processing sms - #{id} - 1")
        mobile= sms.mobile
        message = URI.encode_www_form_component(sms.text)
        url = URI.parse("https://vas.themultimedia.in/domestic/sendsms/bulksms_v2.php?apikey=QVNIUFBSOmxPTW8wQ2VM&type=TEXT&sender=ASHPPR&entityId=1701170987949461409&templateId=#{sms.template_id}&mobile=#{mobile}&message=#{message}")
        http_object = Net::HTTP.new(url.host, url.port)

        http_object.use_ssl = true if url.scheme == 'https'

        request = Net::HTTP::Post.new(url)
        request['Content-Type'] = 'application/x-www-form-urlencoded'
        response = http_object.request(request)
        
        sent = response.is_a?(Net::HTTPSuccess)
        if sent
          puts "Message: #{response.body}"
          message=response.body
        else
          sent=false
          puts "Message failed with response: #{response.body}"
          message=response.body
        end
      rescue Exception => e
        sent = false
        message = e.to_s
        @process_ashpura_sms_logger.info("Error processing SMS: #{e.message} - 2")
      end
  
      sms.update(response: message, sent: sent)
      @process_ashpura_sms_logger.info("Processed SMS ID: #{id}, Sent: #{sent} - 3")
      return true
    end
  end
  