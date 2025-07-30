class ExotelSmsService
  require 'net/http'
  require 'uri'
  require 'json'

  @queue = :exotel_sms_service
  @exotel_sms_service_logger = Logger.new('log/exotel_sms_service.log')

  def self.perform id
    sms = ::SystemSms.find(id)
    begin
      uri = URI('https://9f01cb19b3f1f9e89c5a1c2f838c39f9198e60bea1cd90ee:a04acb8ac7bd1e2ed4c56655649084785ffa18919eecf30f@api.exotel.com/v1/Accounts/dkholdings2/Sms/send')
      res = Net::HTTP.post_form(uri, 'FROM' => 'DKHLDS', 'To' => "#{sms.mobile}", 'Body' => "#{sms.text}", 'DltEntityId' => '1201162824862549561', 'DltTemplateId' => "#{sms.template_id}")
      
      sent=false
      if res.code == "200"
        sent = true
        message = "Success"
      end
      
    rescue Exception => e
      sent = false
      message = e.to_s
      @exotel_sms_service_logger.info("processing sms-#{id} - 4")
    end
    sms.update_attributes(:response=>message, :sent=>sent)
    @exotel_sms_service_logger.info("processing sms-#{id} - 6")
    return true
  end
end
