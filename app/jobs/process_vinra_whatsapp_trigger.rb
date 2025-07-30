class ProcessVinraWhatsappTrigger

  @queue = :process_whatsapp
  @process_vinra_whatsapp_logger = Logger.new('log/process_whatsapp.log')

  def self.perform(id, *args)
    lead = ::Lead.find_by(id: id)
    begin
      formatted_status = args.first == "on_create" ? "on_lead_generation" : lead.status.name.split(' ').map(&:downcase).join('_')
      params = send(formatted_status, lead)
      @process_vinra_whatsapp_logger.info("processing whatsapp notification - #{id} - 1")
      response = AisensyNotificationService.send_vinra_whatsapp_notifications(lead, params)
      sent = response[0]
      @process_vinra_whatsapp_logger.info("processing whatsapp notification - #{id} - 2")
    rescue Exception => e
      sent = false
      message = e.to_s
      @process_vinra_whatsapp_logger.info("Failed to process WhatsApp notification for Lead ID: #{id} - 2 - Error: #{message}")
    end
    @process_vinra_whatsapp_logger.info("processed whatsapp notification for - #{id} - 3")
    return sent
  end

  class << self
    def on_lead_generation(lead)
      {campagin_name: "message_for_new_leads", template_params: []}
    end

    def rnr(lead)
      {campagin_name: "message_for_rnr_lead", template_params: []}
    end
  end
end