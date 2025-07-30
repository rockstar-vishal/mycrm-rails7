class SendNextelSiteVisitDoneNotification

  @queue = :process_sv_done_notification
  @process_sv_done_notification = Logger.new('log/process_sv_done_notification.log')

  def self.perform id
    lead = ::Lead.find_by(id: id)
    begin
      @process_sv_done_notification.info("Processing site visit done notification for lead ID: #{id} - 1")
      url = "https://api.nextel.io/API_V2/Whatsapp/send_template/THc3c1NMdDYybStvYVV5NUd3OGxudz09"
      formatted_project = lead.project.name.downcase.gsub(' - ', ' ').gsub(' ', '_')
      request = {
        type: "buttonTemplate",
        templateId: send(formatted_project)[:template_id],
        templateLanguage: "en",
        templateArgs: [lead.project.banner_image.url],
        sender_phone: "91#{lead.mobile}"
      }
      json_request = JSON.generate(request)

      response = RestClient.post(url, json_request)
      @process_sv_done_notification.info("Processing site visit done notification for lead ID: #{id} - 2")
    rescue Exception => e
      @process_sv_done_notification.info("Failed to send site visit done notification for lead ID: #{id} - 2")
    end
    @process_sv_done_notification.info("Processed site visit done notification for lead ID: #{id} - 3")
    return true
  end

  class << self
    def newton_homes_near_runwal_seagull
      { template_id: "visitform_handewadi" }
    end

    def the_workclub
      { template_id: "visitform_pimpri" }
    end

    def newton_homes_tathawade
      { template_id: "visitform_tathawade" }
    end

    def newton_homes_hadapsar
      { template_id: "visitform_hadapsar" }
    end

    def newton_homes_thergaon_chinchwad
      { template_id: "feedback_royale_2025" }
    end
  end
end
