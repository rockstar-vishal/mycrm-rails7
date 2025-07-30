class ProcessNineNineLead

  @queue = :process_nine_nine_lead
  @process_nine_nine_lead = Logger.new('log/process_nine_nine_lead.log')

  def self.perform(id)
    begin
      lead = Lead.find_by(id: id)
      url = URI("https://www.99acres.com/api-aggregator/discovery/eoi/feedback")
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true
      request = Net::HTTP::Post.new(url)
      request["Content-Type"] = "application/json"
      request.body = JSON.dump({
        "profileId": "#{lead.company.nine_nine_profile_id}",
        "projectName": "#{lead.project_name}",
        "projectId": "#{lead.project.nine_token}",
        "buyerPhone": "#{lead.mobile}",
        "buyerEmail": "#{lead.email}",
        "feedback": "#{lead.comment}",
        "leadCaptureDate": "#{lead.created_at.strftime('%d-%m-%Y')}",
        "dateFormat": "dd-MM-yyyy"
      })
      response = https.request(request)
      if response.kind_of?(Net::HTTPSuccess)
        @process_nine_nine_lead.info("Done - #{lead.id}-----------1")
      else
        @process_nine_nine_lead.info("Lead Processing Failed - #{lead.id}--------2")
      end
      
    rescue Exception => e
      @process_nine_nine_lead.info("Lead Processing Failed--- #{lead.id}------3")
    end
    @process_nine_nine_lead.info("Done - #{lead.id}-----------4")
    return true
  end

end

