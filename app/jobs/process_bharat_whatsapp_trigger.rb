class ProcessBharatWhatsappTrigger
  @queue = :process_whatsapp
  @process_bharat_whatsapp_logger = Logger.new('log/process_whatsapp.log')

  def self.perform(id, *args)
    lead = ::Lead.find_by(id: id)
    begin
      url = "https://backend.api-wa.co/campaign/tradai/api/v2"
      formatted_status = args.first == "on_create" ? "on_lead_generation" : lead.status.name.split(' ').map(&:downcase).join('_')
      request = {
        "apiKey": "#{lead.company.whatsapp_integration.integration_key}",
        "campaignName": send(formatted_status, lead)[:campagin_name],
        "destination": "+91#{lead.mobile.last(10)}",
        "userName": lead.name,
        "templateParams": send(formatted_status, lead)[:template_params]
      }
      if ["on_lead_generation"].include?(formatted_status)
        request['media'] = {
          "url": "#{lead.project.banner_image.url}",
          "filename": "#{lead.project.name.gsub(" ", "_")}.jpg"
        }
      end
      response = RestClient.post(url, request)
      @process_bharat_whatsapp_logger.info("processing WhatsApp notification for Lead ID: #{id} - 1")
    rescue Exception => e
      @process_bharat_whatsapp_logger.error("Failed to process WhatsApp notification for Lead ID: #{id} - 2 - Error: #{e.message}")
    end
    @process_bharat_whatsapp_logger.info("Processed WhatsApp notification for Lead ID: #{id} - 2")
    true
  end

  class << self

    def on_lead_generation(lead)
      {campagin_name: "OnLeadCreation", template_params: []}
    end

    def booking_done(lead)
      {campagin_name: "booking_confirm_api", template_params: ["$Name"]}
    end

    def visit_plan(lead)
      tentative_visit_planned = lead.tentative_visit_planned
      date = tentative_visit_planned.strftime("%d/%m/%Y")
      time = tentative_visit_planned.strftime("%I:%M %p")
      {campagin_name: "site_visit_confirm_api", template_params: ["$Name", date, time, lead.user&.name, lead.project&.address]}
    end

    def visit_scheduled(lead)
      tentative_visit_planned = lead.tentative_visit_planned
      date = tentative_visit_planned.strftime("%d/%m/%Y")
      time = tentative_visit_planned.strftime("%I:%M %p")
      {campagin_name: "site_visit_reminder_api", template_params: ["$Name", date, time, lead.user&.name, lead.project&.address]}
    end
  end
end
