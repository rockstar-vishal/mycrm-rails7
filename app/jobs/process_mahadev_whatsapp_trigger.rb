class ProcessMahadevWhatsappTrigger

  @queue = :process_whatspp
  @process_mahadev_whatsapp_logger = Logger.new('log/process_whatsapp.log')

  def self.perform(id, *args)
    lead = ::Lead.find_by(id: id)
    begin
      url = "https://backend.api-wa.co/campaign/smartping/api/v2"
      # if args.first=="on_create"
      # end
      formatted_status = "new_lead_generation"
      request = {
        "apiKey": "#{lead.company.whatsapp_integration.integration_key}",
        "campaignName": send(formatted_status, lead)[:campagin_name],
        "destination": "+91#{lead.mobile.last(10)}",
        "userName": lead.name,
        "templateParams": send(formatted_status, lead)[:template_params]
      }
      request['media'] = {
        "url": "#{lead.project.brochure_link}",
        "filename": "#{lead.project.name}"
      }
      response = RestClient.post(url, request)
      @process_mahadev_whatsapp_logger.info("processing whatsapp-#{id} - 1")
    rescue Exception => e
      @process_mahadev_whatsapp_logger.info("processing whatsapp-#{id} - 2")
    end
    @process_mahadev_whatsapp_logger.info("processing sms-#{id} - 2")
    return true
  end

  class << self

    def new_lead_generation(lead)
      {campagin_name: "onNewLeadCreation", template_params: [lead.name]}
    end
  end

end
