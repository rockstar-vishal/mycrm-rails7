class ProcessRavimaWhatsappTrigger

  @queue = :process_whatsapp
  @process_ravima_whatsapp_logger = Logger.new('log/process_whatsapp.log')
  def self.perform(id, *args)
    lead = ::Lead.find_by(id: id)
    begin
      url = "https://api.nextel.io/API_V2/Whatsapp/send_template/THc3c1NMdDYybStvYVV5NUd3OGxudz09"
      if args.first == "on_create"
        formatted_status = "lead_creation"
      else
        formatted_status = lead.status.name.split(' ').map { |s| s.downcase }.join('_')
      end
      temp_data = send(formatted_status, lead)
      request = {
        type: "buttonTemplate",
        templateId: temp_data[:template_id],
        templateLanguage: "en",
        templateArgs: temp_data[:template_params],
        sender_phone: "91#{lead.mobile}"
      }
      json_request = JSON.generate(request)

      response = RestClient.post(url, json_request)

      @process_ravima_whatsapp_logger.info("processing whatsapp-#{id} - 1")
    rescue Exception => e
      @process_ravima_whatsapp_logger.info("processing whatsapp-#{id} - 2")
    end
    @process_ravima_whatsapp_logger.info("processing sms-#{id} - 2")
    return true
  end

  class << self
    def lead_creation(lead)
      { template_id: "newleadcrm", template_params: [lead.name, lead.project.name] }
    end

    def cold(lead)
      { template_id: "coldleadcrm", template_params: [lead.name, lead.project.name]}
    end

    def warm(lead)
      { template_id: "warmleadcrm", template_params: [lead.name, lead.project.name] }
    end

    def hot(lead)
      { template_id: "hotleadcrm", template_params: [lead.name, lead.project.name] }
    end

    def unqualified(lead)
      { template_id: "unqualifiedleadcrm", template_params: [lead.name, lead.project.name]}
    end

    def send_details(lead)
      { template_id: "senddetailleadcrm", template_params: [lead.name, lead.project.name]}
    end

    def lost(lead)
      { template_id: "lostleadcrm", template_params: [lead.name, lead.project.name] }
    end

    def call_not_connected(lead)
      { template_id: "cncleadcrm", template_params: [lead.name, lead.project.name]}
    end

    def call_not_received(lead)
      { template_id: "cnrleadcrm", template_params: [lead.name] }
    end

    def site_visit_planned(lead)
      { template_id: "svplannedleadcrm", template_params: [lead.name, lead.project.name]}
    end

    def site_visit_done(lead)
      { template_id: "svdoneleadcrm", template_params: [lead.name, lead.project.name]}
    end

    def site_visit_cold(lead)
      { template_id: "svcoldleadcrm", template_params: [lead.name] }
    end

    def site_visit_warm(lead)
      { template_id: "svwarmleadcrm", template_params: [lead.name, lead.project.name] }
    end

    def site_visit_hot(lead)
      { template_id: "svhotleadcrm", template_params: [lead.name] }
    end

    def site_visit_lost(lead)
      { template_id: "svlostleadcrm", template_params: [lead.name] }
    end

    def booked(lead)
      { template_id: "bookedleadcrm", template_params: [lead.name, lead.project.name] }
    end
  end
end
