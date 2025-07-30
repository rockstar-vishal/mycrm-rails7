class ProcessAisensyNotifications
  @queue = :process_aisensy_notification
  @process_aisensy_notification = Logger.new('log/process_aisensy_notification.log')

  def self.perform id
    lead = ::Lead.find_by(id: id)
    begin
      @process_aisensy_notification.info("processing whatsapp notification - #{id} - 1")
      response = AisensyNotificationService.send_sv_done_notification(lead)
      sent = response[0]
      @process_aisensy_notification.info("processing whatsapp notification - #{id} - 2")
    rescue Exception => e
      sent = false
      message = e.to_s
      @process_aisensy_notification.info("whatsapp notification failed for - #{id} - 2")
    end
    @process_aisensy_notification.info("processed whatsapp notification for - #{id} - 3")
    return sent
  end
end