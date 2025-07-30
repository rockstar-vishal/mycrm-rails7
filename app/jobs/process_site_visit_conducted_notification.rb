class ProcessSiteVisitConductedNotification

  @queue = :process_email
  @process_email_logger = Logger.new('log/process_email.log')

  def self.perform id
    email = ::Email.find(id)
    begin
      @process_email_logger.info("processing sms-#{id}")
      ClientsMailer.site_visit_conducted_mail(email).deliver!
      sent = true
      message = "Sent Succesfully"
    rescue Exception => e
      sent = false
      message = e.to_s
      @process_email_logger.info("processing sms-#{id} - 4")
    end
    email.update_attributes(:response=>message, :sent=>sent)
    @process_email_logger.info("processing sms-#{id} - 6")
    return true
  end

end