class ProcessNextelLeads

  @queue = :process_nextel_leads_creation
  @process_panom_whatsapp_logger = Logger.new('log/process_nextel_leads_creation.log')

  def self.perform(id)
    lead = ::Lead.find_by(id: id)
    begin
      url = "https://api.nextel.io/WEBHOOK_V1/Audience/set/de7f47e09c8e05e6021ababdf6bc58e7"
      request = {
        name: lead.name,
        phone: lead.mobile,
        email: lead.email,
        tag2: lead.status&.name
      }

      response = RestClient.post(url, request)
      @process_panom_whatsapp_logger.info("processing nextel lead creation-#{id} - 1")
    rescue Exception => e
      @process_panom_whatsapp_logger.info("processing nextel lead creation-#{id} - 2")
    end
    @process_panom_whatsapp_logger.info("processing nextel lead creation-#{id} - 2")
    return true
  end
end
