class ProcessSkfortuneWhatsappTrigger

  @queue = :process_whatsapp
  @process_skfortune_whatsapp_logger = Logger.new('log/process_whatsapp.log')

  def self.perform id
    lead = ::Lead.find_by(id: id)
    begin
      url = "https://partners.pinbot.ai/v2/messages"
      headers = {
        'Content-Type': 'application/json',
        'apiKey': lead.company.whatsapp_integration.integration_key,
        'wanumber': '917758887458'
      }
      request = {
        messaging_product: "whatsapp",
        recipient_type: "individual",
        to: "+91#{lead.mobile.last(10)}",
        type: "template",
        template: {
          language: {
            code: "en"
          },
          name: "message_template_crm",
          components: []
        }
      }

      response = RestClient.post(url, request.to_json, headers)
      @process_skfortune_whatsapp_logger.info("processing WhatsApp notification for Lead ID: #{id} - 1")
    rescue Exception => e
      @process_skfortune_whatsapp_logger.info("Failed to process WhatsApp notification for Lead ID: #{id} - 2 - Error: #{e.message}")
    end
    @process_skfortune_whatsapp_logger.info("Processed WhatsApp notification for Lead ID: #{id} - 2")
    return true
  end
end
