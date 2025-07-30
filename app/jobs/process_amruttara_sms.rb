class ProcessAmruttaraSms
  require 'uri'
  require 'net/http'
  require 'json'

  @queue = :process_amruttara_sms
  @process_amruttara_sms_logger = Logger.new('log/process_amruttara_sms.log')

  def self.perform id
    sms = ::SystemSms.find(id)
   
    begin
      @process_amruttara_sms_logger.info("processing sms - #{id} - 1")

      message = URI.encode_www_form_component(sms.text)
      url = URI.parse("http://control.yourbulksms.com/api/sendhttp.php?authkey=36325f7461726133313508&route=2&country=0&mobiles=#{sms.mobile}&sender=MEHTAU&message=#{message}&DLT_TE_ID=#{sms.template_id}")

      http_object = Net::HTTP.new(url.host, url.port)
      http_object.use_ssl = false

      request = Net::HTTP::Post.new(url)
      response = http_object.request(request)

      if response.kind_of?(Net::HTTPSuccess)
        sent = true
        message = response.body
        @process_amruttara_sms_logger.info("processing sms - #{id} - 2")
      else
        sent = false
        message = "HTTP Error: #{response.code}, #{response.message}"
        @process_amruttara_sms_logger.info("Failed to send SMS. #{message} - 2")
      end
    rescue Exception => e
      sent = false
      message = e.to_s
      @process_amruttara_sms_logger.info("Error processing SMS: #{e.message} - 2")
    end

    sms.update(response: message, sent: sent)
    @process_amruttara_sms_logger.info("Processed SMS ID: #{id}, Sent: #{sent} - 3")
    return true
  end
end
