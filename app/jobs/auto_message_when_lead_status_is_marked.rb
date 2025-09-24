class AutoMessageWhenLeadStatusIsMarked
  @queue = :process_whatsapp
  @@process_gbkgroup_whatsapp_logger = Logger.new('log/process_whatsapp.log')

  def self.perform(id, *args)
    lead = ::Lead.find_by(id: id)
    return unless lead

    campaign_data = auto_send(lead)
    destination = "+91#{lead.mobile.to_s.last(10)}"

    begin
      url = "https://backend.api-wa.co/campaign/tradai/api/v2"
      request = {
        apiKey: lead.company.whatsapp_integration.integration_key,
        campaignName: campaign_data[:campaign_name],
        destination: destination,
        userName: lead.name,
        templateParams: campaign_data[:template_params]
      }
      response = RestClient.post(url, request.to_json, { content_type: :json, accept: :json })
      body = JSON.parse(response.body) rescue {}
      status = body["success"].to_s == "true" ? :success : :failed
      WhatsappMessageLog.create!(
        lead: lead,
        campaign_name: campaign_data[:campaign_name],
        destination: destination,
        template_params: campaign_data[:template_params],
        status: status,
        response: response.body
      )
      @@process_gbkgroup_whatsapp_logger.info("WhatsApp sent for Lead ##{id}, status: #{status}, response: #{response.body}")

    rescue => e
      WhatsappMessageLog.create!(
        lead: lead,
        campaign_name: campaign_data[:campaign_name],
        destination: destination,
        template_params: campaign_data[:template_params],
        status: :failed,
        response: e.message
      )
      @@process_gbkgroup_whatsapp_logger.error("Error sending WhatsApp for Lead ##{id}: #{e.message}")
    end

    @@process_gbkgroup_whatsapp_logger.info("Completed processing Lead ##{id}")
    true
  end

  class << self
    def auto_send(lead)
      {
        campaign_name: "AutoMessageHotWarmCold",
        template_params: [
          lead.name,
          lead.project&.name,
          "https://qr-#{lead.company.domain}/SiteVisit/#{lead.lead_no}"
        ]
      }
    end
  end
end
