require 'uri'
require "net/http"

class AisensyNotificationService
  class << self
    def send_sv_done_notification(lead)
      begin
        communication_template = lead.company.communication_templates.for_wp.last
        trigger_event = communication_template.trigger_events.to_lead.where(to_status: lead.status_id, trigger_type: ['On Create', 'On Update']).last rescue nil

        return false, 'No valid trigger event found' unless trigger_event.present?

        communication_attributes = trigger_event.communication_attributes
        return false, 'No communication attributes found' unless communication_attributes.present?

        url = URI.parse("https://backend.aisensy.com/campaign/t1/api")
        variables = prepare_variables(lead, communication_attributes)
        payload = build_payload(lead, variables, trigger_event.template_id)

        request = Net::HTTP::Post.new(url)
        request.content_type = 'application/json'
        request.body = payload

        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        response = http.request(request)
        if response.is_a?(Net::HTTPSuccess)
          return true, response
        else
          return false, response.message
        end
      rescue => e
        return false, e.message
      end
    end

    def send_vinra_whatsapp_notifications lead, params
      begin
        url = "https://backend.aisensy.com/campaign/t1/api"
        request = {
          apiKey: lead.company.whatsapp_integration.integration_key,
          campaignName: params[:campagin_name],
          destination: "91#{lead.mobile}",
          userName: lead.name,
          templateParams: params[:template_params]
        }.to_json
        headers = { 'Content-Type': 'application/json' }
        response = RestClient.post(url, request, headers)
        if response.code == 200
          return true, response
        else
          return false, "Error: Received HTTP #{response.code}"
        end
      rescue Exception => e
        return false, e.message
      end
    end

    private

    def prepare_variables(lead, communication_attributes)
      variables = []
      communication_attributes.each do |attribute|
        variable_mapping = attribute.variable_mapping rescue nil

        if variable_mapping.present?
          associated_object = lead.class == variable_mapping.variable_type.constantize ? lead : lead.send(variable_mapping.system_assoication)
          variables << associated_object.send(variable_mapping.system_attribute)
        end
      end

      variables.compact
    end

    def build_payload(lead, variables, template_id)
      {
        apiKey: lead.company.whatsapp_integration.integration_key,
        campaignName: template_id,
        destination: "91#{lead.mobile}",
        userName: lead.name,
        templateParams: variables
      }.to_json
    end
  end
end
