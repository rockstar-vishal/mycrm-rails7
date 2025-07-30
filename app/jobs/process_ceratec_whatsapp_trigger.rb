class ProcessCeratecWhatsappTrigger

  @queue = :process_ceratec_whatsapp
  @process_whatsapp_logger = Logger.new('log/process_ceratec_whatsapp.log')

  def self.perform id
    lead = ::Lead.find_by(id: id)
    begin
      formatted_status = lead.status.name.split(' ').map{|s| s.downcase}.join('_')
      message_body = send(formatted_status, lead)[:message]
      message_body_encoded = URI.encode_www_form_component(message_body)
      url = "http://cp.sendwpsms.com/api/sendwpget?username=ceratec&password=ceratec1023&message=#{message_body_encoded}&registerednumber=9167295109&to=#{lead.mobile}&type=m&uuid=e6119716-6d8a-4888-baea-cc92f50879ec"

      response = RestClient.get(url, {content_type: "application/json", accept: 'application/json'})
      @process_whatsapp_logger.info("processing whatsapp-#{id} - 1")
    rescue Exception => e
      @process_whatsapp_logger.info("processing whatsapp-#{id} - 2")
    end
    @process_whatsapp_logger.info("processing sms-#{id} - 2")
    return true
  end

  class << self
    def site_visit_done(lead)
      { message: "Hello #{lead.name}%0D%0A%0D%0AIt was indeed a pleasure having you at our site. You are attended by Sales Executive #{lead.user.name}%0D%0AMobile Number :- #{lead.user.mobile}%0D%0AFor any assistance, you may reach out to our Team Leader Madhu Gaikwad %0D%0AMobile Number:- 9579663732%0D%0A%0D%0AThanks and Regards,%0D%0ACeratec Group%0D%0AWalkthrough Link:- https://youtu.be/zLkpUM3dmS8" }
    end

    def new(lead)
      { message: "Hello #{lead.name}%0D%0A%0D%0AWelcome to Ceratec Group. Thank you for expressing your interest in our projects. Ceratec Group is a Leading Real Estate Development Brand in Pune with a Palatial Residential Projects. It would be our pleasure to help you choose the best Home for you.%0D%0A%0D%0ABest Regards,%0D%0ATeam Ceratec Group" }
    end

    def booked(lead)
      { message: "Hello #{lead.name}%0D%0A%0D%0AWelcome to Ceratec Group. Thank you for expressing your interest in our projects #{lead.project.name}. Ceratec Group is a Leading Real Estate Development Brand in Pune with a Palatial Residential Projects. It would be our pleasure to help you choose the best Home for you.%0D%0A%0D%0AThanks And Regards,%0D%0ACeratec Group" }
    end
  end
  
end
  