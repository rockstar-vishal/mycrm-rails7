class ProcessLeadOnCreationEmail
  @queue = :process_email
  @process_email_logger = Logger.new('log/process_email.log')

  def self.perform id
    email = ::Email.find(id)
    begin
      @process_email_logger.info("processing lead creation-#{id}")
      ClientsMailer.lead_on_creation_email(email).deliver!
      sent = true
      message = "Sent Succesfully"
    rescue Exception => e
      sent = false
      message = e.to_s
      @process_email_logger.info("processing lead creation-#{id} - 4")
    end
    email.update(:response=>message, :sent=>sent)
    @process_email_logger.info("processing lead creation-#{id} - 6")
    return true
  end

end