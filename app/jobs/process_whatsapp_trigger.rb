class ProcessWhatsappTrigger

  @queue = :process_whatspp
  @process_whatsapp_logger = Logger.new('log/process_email.log')

  def self.perform id
    lead = ::Lead.find_by(id: id)
    begin
      url = "https://backend.api-wa.co/campaign/tradai/api"
      formatted_status = lead.status.name.split(' ').map{|s| s.downcase}.join('_')
      request = {
        "apiKey": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY0YjRjOGQxZjM4ZWZlMGJkZDA5ODE1MCIsIm5hbWUiOiJBVVRPTU9WSUxMIFRFQ0hOT0xPR0lFUyBQUklWQVRFIExJTUlURUQiLCJhcHBOYW1lIjoiQWlTZW5zeSIsImNsaWVudElkIjoiNjRiNGM4ZDFjNzVhMWQwYmVhMWRmYTc0IiwiYWN0aXZlUGxhbiI6IlBST19NT05USExZIiwiaWF0IjoxNjkzNDc0MDA1fQ.ipg3dqvTkpGxNBZFGz7zqtRLSzpEnprBkHafoGh8FzU",
        "campaignName": send(formatted_status, lead)[:campagin_name],
        "destination": "+91#{lead.mobile.last(10)}",
        "templateParams": send(formatted_status, lead)[:template_params]
      }
      response = RestClient.post(url, request)
      @process_whatsapp_logger.info("processing whatsapp-#{id} - 1")
    rescue Exception => e
      @process_whatsapp_logger.info("processing whatsapp-#{id} - 2")
    end
    @process_whatsapp_logger.info("processing sms-#{id} - 2")
    return true
  end

  class << self

    def requested(lead)
      {campagin_name: 'Requested', template_params: [lead.name, lead.reg_no.to_s]}
    end

    def approved(lead)
       {campagin_name: 'Approved', template_params: [lead.name, lead.reg_no.to_s]}
    end

    def pickup_done(lead)
      {campagin_name: 'PickUp Done', template_params: [lead.name, lead.reg_no.to_s]}
    end

    def estimation_sent(lead)
      {campagin_name: 'Estimation Sent', template_params: [lead.name, lead.customer_amount.to_s]}
    end

    def service_start(lead)
      {campagin_name: 'Service Start', template_params: [lead.name, lead.reg_no.to_s]}
    end

    def service_complete(lead)
      {campagin_name: 'Service Complete', template_params: [lead.name, lead.reg_no.to_s]}

    end

    def invoice_sent(lead)
      {campagin_name: 'Invoice Sent', template_params: [lead.name, lead.customer_amount.to_s, lead.mobile.last(10)]}
    end

  end

end
