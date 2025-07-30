class ProcessAshapuraWhatsappTrigger

  @queue = :process_whatsapp
  @process_ashapura_whatsapp_logger = Logger.new('log/process_whatsapp.log')

  def self.perform id
    lead = ::Lead.find_by(id: id)
    begin
      token = generate_token
      if token
        url = "https://portal.cpass.co.in/whatsapp/api/v1/send"
        request = {
          to: ["91#{lead.mobile.last(10)}"],
          message: {
            template_name: "rangrekha100",
            language: "en",
            type: "template",
            body_params: [],
            header_params: [
              "#{lead.project.banner_image&.url}"
            ]
          }
        }
        headers = {
          "Content-Type": "application/json",
          "Authorization": "Bearer #{token}"
        }

        response = RestClient.post(url, request.to_json, headers)
        @process_ashapura_whatsapp_logger.info("processing WhatsApp notification for Lead ID: #{id} - 1")
      end
    rescue Exception => e
      @process_ashapura_whatsapp_logger.error("Failed to process WhatsApp notification for Lead ID: #{id} - 2 - Error: #{e.message}")
    end
    @process_ashapura_whatsapp_logger.info("Processed WhatsApp notification for Lead ID: #{id} - 2")
    return true
  end

  private

  def self.generate_token
    begin
      url = "https://portal.cpass.co.in/api/authentication/login"
      request = {
        username: "ashapurarealty",
        password: "r67)ELZB"
      }
      response = RestClient.post(url, request.to_json, { "Content-Type": "application/json" })
      return JSON.parse(response.body)["accessToken"] if response.code == 200
    rescue Exception => e
      return nil
    end
  end
end
