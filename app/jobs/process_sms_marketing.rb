class ProcessSmsMarketing
  require 'uri'
  require 'net/http'
  require 'json'

  @queue = :process_sms_marketing
  @process_sms_marketing_logger = Logger.new('log/process_sms_marketing.log')

  def self.perform id
    sms = ::SystemSms.find(id)
    begin
      if sms.company.template_flag_name == "ravima"
        url = sms.company.sms_integration.url
        encoded_text = URI.encode_www_form_component(sms.text)
        url = URI("#{url}/api/mt/SendSMS?user=\Apiravimaventures&password=Ravimaventures987&senderid=RAVEMA&channel=Trans&DCS=0&flashsms=0&number=#{sms.mobile}&text=#{encoded_text}&route=8&dlttemplateid=#{sms.template_id}")
        http = Net::HTTP.new(url.host, url.port);
        request = Net::HTTP::Get.new(url)
        response = http.request(request)
        message_body = JSON.parse response.body
        message = message_body["MessageData"].to_s
        @process_sms_marketing_logger.info("processing sms-#{id} - 2")
        
        sent = true
        @process_sms_marketing_logger.info("processing sms-#{id} - 3")
      else
        api_key = "IyMlkNH+SILnfqcvcJemhFTH0J01Wppbwa2Iabb/Q7w="
        client_id="5e71d8b9-4c60-4a1d-85fe-d29e6320f5b7"
        @process_sms_marketing_logger.info("processing sms-#{id}")
        url_encoded_sms_text = URI.encode_www_form_component(sms.text)

        uri = URI('http://164.52.205.46:6005/api/v2/SendSMS')
        params = { :ApiKey => "#{api_key}", :ClientId => "#{client_id}" , SenderId: "RAVEMA", Message: "#{sms.text}", MobileNumbers: "#{sms.mobile}", TemplateId: "#{sms.template_id}" }
        uri.query = URI.encode_www_form(params)

        response = Net::HTTP.get(uri)

        @process_sms_marketing_logger.info("processing sms-#{id} - 2")
        res=JSON.parse(response)
        sent = true
        message = res["Data"].first["MessageErrorDescription"]
        @process_sms_marketing_logger.info("processing sms-#{id} - 3")
      end
    rescue Exception => e
      sent = false
      message = e.to_s
      @process_sms_marketing_logger.info("processing sms-#{id} - 4")
    end
    sms.update(:response=>message, :sent=>sent)
    @process_sms_marketing_logger.info("processing sms-#{id} - 6")
    return true
  end
end
  
