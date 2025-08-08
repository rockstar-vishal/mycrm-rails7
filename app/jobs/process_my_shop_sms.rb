class ProcessMyShopSms
  require 'uri'
  require 'net/http'
  require 'json'

  @queue = :process_my_shops_sms
  @process_sms_marketing_logger = Logger.new('log/process_my_shops_sms.log')

  def self.perform id
    sms = ::SystemSms.find(id)
    begin
      api_key = sms.company.sms_integration.integration_key.blank? ? "z9Wgo9QuwFBIVDE5" : sms.company.sms_integration.integration_key
      sender_id = sms.company.notification_templates.find_by(notification_category: "lead create")&.sender_id || "CSRLTY"
      @process_sms_marketing_logger.info("processing sms-#{id}")
      url_encoded_sms_text = URI.encode_www_form_component(sms.text)

      uri = URI('http://mysmsshop.in/V2/http-api.php')
      params = { :apikey => "#{api_key}", senderid: "#{sender_id}", message: "#{sms.text}", number: "#{sms.mobile}"}
      uri.query = URI.encode_www_form(params)
      response = Net::HTTP.get(uri)

      @process_sms_marketing_logger.info("processing sms-#{id} - 2")
      res=JSON.parse(response)
      sent = true
      message = res["data"]
      @process_sms_marketing_logger.info("processing sms-#{id} - 3")
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
