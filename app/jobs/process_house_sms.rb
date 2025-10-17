class ProcessHouseSms
  require 'uri'
  require 'net/http'
  require 'json'
  require 'cgi'

  @queue = :process_house_sms
  @process_house_sms_logger = Logger.new('log/process_house_sms.log')

  def self.perform id
    sms = ::SystemSms.find(id)

    begin
      @process_house_sms_logger.info("processing sms - #{id} - 1")
      mobile= sms.mobile
      message = CGI.escape(sms.text).gsub('+', '%20').gsub('.', '%2E').gsub('-', '%2D')
      url = URI.parse("http://truebulksms.biz/api.php?username=saideep&password=273493&sender=SDCONS&sendto=91#{mobile}&message=#{message}&PEID=1701175748367269377&templateid=#{sms.template_id}")
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
      @process_house_sms_logger.info("Error processing SMS: #{e.message} - 2")
    end

    sms.update(response: message, sent: sent)
    @process_house_sms_logger.info("Processed SMS ID: #{id}, Sent: #{sent} - 3")
    return true
  end
end
  