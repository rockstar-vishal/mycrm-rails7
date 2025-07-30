class ProcessUrbanWhatsappTrigger

    @queue = :process_whatspp
    @process_urban_whatsapp_logger = Logger.new('log/process_whatsapp.log')
  
    def self.perform id
      lead = ::Lead.find_by(id: id)
      begin

        url = "https://backend.api-wa.co/campaign/tradai/api"
        formatted_status = lead.status.name.split(' ').map{|s| s.downcase}.join('_')
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
          "filename": "#{lead.project.name}.png"
        } if (formatted_status == "new")
        response = RestClient.post(url, request)
        @process_urban_whatsapp_logger.info("processing whatsapp-#{id} - 1")
      rescue Exception => e
        @process_urban_whatsapp_logger.info("processing whatsapp-#{id} - 2")
      end
      @process_urban_whatsapp_logger.info("processing sms-#{id} - 2")
      return true
    end
  
    class << self
  
      def attempted(lead)
        {campagin_name: 'FollowUp', template_params: [lead.name, lead.project.name, "-", lead.created_at.strftime("%B,%d %H:%M %p")]}
      end

      def scheduled_for_visit(lead)
        {campagin_name: 'VisitConfirmation', template_params: [lead.name, lead.tentative_visit_planned.strftime("%B,%d"), lead.tentative_visit_planned.strftime("%H:%M %p"), lead.project.name]}
      end

      def visited_now_follow_up(lead)
        {campagin_name: 'VisitFeedback', template_params: [lead.name]}
      end

      def new(lead)
        {campagin_name: 'ProjectDetailsOnLaunch', template_params: [lead.name, lead.project.name]}
      end
    end
  
  end
  