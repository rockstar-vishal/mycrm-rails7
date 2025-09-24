class ProcessGbkgroupWhatsappTrigger
  @queue = :process_whatsapp
  @process_gbkgroup_whatsapp_logger = Logger.new('log/process_whatsapp.log')
  def self.perform(id, *args)
    lead = ::Lead.find_by(id: id)
    begin
      url = "https://backend.api-wa.co/campaign/tradai/api/v2"
      if args.first == "on_create"
        formatted_status = "lead_creation"
      elsif args&.include?('visit_done')
        formatted_status = "site_visit_done"
      else
        formatted_status = lead.status.name.split(' ').map { |s| s.downcase }.join('_')
      end
      campaign_data = send(formatted_status, lead, args.first)
      filename = lead.project.name.split(' ').map { |s| s.downcase }.join('_')
      request = {
        "apiKey": "#{lead.company.whatsapp_integration.integration_key}",
        "campaignName": campaign_data[:campagin_name],
        "destination": "+91#{lead.mobile.last(10)}",
        "userName": lead.name,
        "templateParams": campaign_data[:template_params]
      }
      request['media'] = {
        "url": "https://d3jt6ku4g6z5l8.cloudfront.net/FILE/6353da2e153a147b991dd812/4079142_dummy.pdf",
        "filename": "#{filename}"
      } if ["site_visit_done", "visit_scheduled"].include?(formatted_status)
      response = RestClient.post(url, request)
      @process_gbkgroup_whatsapp_logger.info("processing whatsapp-#{id} - 1")
    rescue Exception => e
      @process_gbkgroup_whatsapp_logger.info("processing whatsapp-#{id} - 2")
    end
    @process_gbkgroup_whatsapp_logger.info("processing sms-#{id} - 2")
    return true
  end

  class << self
    def lead_creation(lead, arg)
      { campagin_name: "3_lead_new", template_params: [lead.name] }
    end

    def site_visit_planned(lead, arg)
      { campagin_name: "SiteVisitPlanned", template_params: [lead.name, lead.project.name, lead.tentative_visit_planned&.strftime("%d-%B-%Y, %H:%M %p") || "Date & Time", lead.user.name] }
    end

    def site_visit_done(lead, extra_param)
      { campagin_name: "SiteVisitDone", template_params: [lead.name, lead.project.name, extra_param, lead.user.name] }
    end

    def visit_scheduled(lead, arg)
      { campagin_name: "SiteVisitReminder", template_params: [lead.name, lead.project.name, lead.user.name] }
    end
    def booked(lead, arg)
      { campagin_name: "Booked", template_params: [lead.name, lead.project.name ] }
    end
  end
end
