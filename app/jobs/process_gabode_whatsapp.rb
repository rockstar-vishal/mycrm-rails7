class ProcessGabodeWhatsapp
  @queue = :process_whatspp
  @process_gabode_whatsapp_logger = Logger.new('log/process_whatsapp.log')

  def self.perform(template_name, id, body_values, recipient)
    lead=::Lead.find_by(id: id)
    begin
      url = "https://server.gallabox.com/devapi/messages/whatsapp"
      headers = {
        "apiSecret" => (lead.company.whatsapp_integration.token rescue nil),
        "apiKey" => (lead.company.whatsapp_integration.integration_key rescue nil),
        "Content-Type" => "application/json"
      }
      body = {
        channelId: "64a170a23f806f62b0df2d20",
        channelType: "whatsapp",
        recipient: {
          name: recipient['name'],
          phone: recipient['phone']
        },
        whatsapp: {
          type: "template",
          template: {
            templateName: template_name,
            bodyValues: body_values
          }
        }
      }.to_json
      response = RestClient.post(url, body, headers)
      @process_gabode_whatsapp_logger.info("processing whatsapp-#{id} - 1")
    rescue Exception => e
      @process_gabode_whatsapp_logger.info("processing whatsapp-#{id} - 2")
    end
  end
end