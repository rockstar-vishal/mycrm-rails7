class ProcessPanomWhatsappTrigger

    @queue = :process_whatspp
    @process_panom_whatsapp_logger = Logger.new('log/process_whatsapp.log')
  
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
        # Media file for the file template
        request['media'] = {
          "url": "#{lead.project.project_brochure.url}",
          "filename": "#{lead.project.name}.pdf"
        } if (["non_contactable","not_answered","details_shared","call_back","visit_done","on_lead_generation"].include?(formatted_status))
        response = RestClient.post(url, request)
        @process_panom_whatsapp_logger.info("processing whatsapp-#{id} - 1")
      rescue Exception => e
        @process_panom_whatsapp_logger.info("processing whatsapp-#{id} - 2")
      end
      @process_panom_whatsapp_logger.info("processing sms-#{id} - 2")
      return true
    end
  
    class << self

      def on_lead_generation(lead)
        {campagin_name: "OnLeadCreation", template_params: [lead.name]}
      end
  
      def not_answered(lead)
        missed_notification(lead)
      end

      def non_contactable(lead)
        missed_notification(lead)
      end

      def dead(lead)
        inactive(lead)
      end

      def not_interested(lead)
        inactive(lead)
      end

      def lsv_dead(lead)
        inactive(lead)
      end

      def visit_done(lead)
        {campagin_name: "AfterSiteVisit1", template_params: [lead.name]}
      end

      def visit_scheduled(lead)
        {campagin_name: "VisitScheduled", template_params: [lead.name, lead.project.name, lead.tentative_visit_planned.strftime("%d-%B-%Y, %H:%M %p")]}
      end

      def details_shared(lead)
        {campagin_name: "InterestedLead2", template_params: [lead.name]}
      end

      def call_back(lead)
        {campagin_name: "CallBack2", template_params: [lead.name]}
      end

      def inactive(lead)
        {campagin_name: 'NotInterested', template_params: [lead.name]}
      end

      def missed_notification(lead)
        {campagin_name: 'MissedNotification2', template_params: [lead.name]}
      end
    end
  
  end
  