class ProcessVmBuilderWhatsappTrigger

  @queue = :process_whatspp
  @process_vmb_whatsapp_logger = Logger.new('log/process_whatsapp.log')

  def self.perform(id, *args)
    lead = ::Lead.find_by(id: id)
    begin
      url = "https://backend.api-wa.co/campaign/tradai/api"
      if args.first=="on_create"
        formatted_status = "on_lead_generation"
      else
        formatted_status = lead.status.name.split(' ').map{|s| s.downcase}.join('_')
      end

      request = {
        "apiKey": "#{lead.company.whatsapp_integration.integration_key}",
        "campaignName": send(formatted_status, lead)[:campagin_name],
        "destination": "+91#{lead.mobile.last(10)}",
        "userName": lead.name,
        "templateParams": send(formatted_status, lead)[:template_params]
      }

      request['media'] = {
        "url": "#{lead.project.banner_image.url}",
        "filename": "#{lead.project.name.gsub(" ", "_")}.jpg"
      } if (["on_lead_generation", "site_visit_done", "site_visit_planned"].include?(formatted_status))

      response = RestClient.post(url, request)
      @process_vmb_whatsapp_logger.info("processing whatsapp-#{id} - 1")
    rescue Exception => e
      @process_vmb_whatsapp_logger.info("processing whatsapp-#{id} - 2")
    end
    @process_vmb_whatsapp_logger.info("processing sms-#{id} - 2")
    return true
  end

  class << self
    def on_lead_generation(lead)
      {campagin_name: "OnLeadCreation", template_params: []}
    end

    def site_visit_done(lead)
      {campagin_name: "AfterSiteVisitDone", template_params: []}
    end

    def booked(lead)
      {campagin_name: "AfterSiteBooked", template_params: [lead.lead_no, lead.lead_no]}
    end

    def site_visit_planned(lead)
      tentative_visit_planned = lead.tentative_visit_planned
      date = tentative_visit_planned&.strftime("%Y-%m-%d")
      time = tentative_visit_planned&.strftime("%H:%M:%S")
      {campagin_name: "SiteVisitPlanned", template_params: [date, time]}
    end
  end
end