class ProcessValueFirstSms

  @queue = :process_value_first_sms
  @process_email_logger = Logger.new('log/process_value_first_sms.log')

  def self.perform id
    sms = ::SystemSms.find(id)
    begin
      sms_service = ValueFirstSmsService.new(sms.company, {data: sms.mobile, message: sms.text, template: sms.template_id})
      response = sms_service.send_sms
      @process_email_logger.info("processing sms-#{id} - 2")
      sent = true
      message = response[0]
      @process_email_logger.info("processing sms-#{id} - 3")
    rescue Exception => e
      sent = false
      message = e.to_s
      @process_email_logger.info("processing sms-#{id} - 4")
    end
    sms.update(:response=>message, :sent=>sent)
    @process_email_logger.info("processing sms-#{id} - 6")
    return true
  end
end