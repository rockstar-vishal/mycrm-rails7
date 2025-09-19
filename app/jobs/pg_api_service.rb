class PgApiService
  require 'net/http'
  require 'uri'
  require 'json'

  @queue = :pg_api_service
  @pg_api_service_logger = Logger.new('log/pg_api_service.log')

  def self.perform id
    sms = ::SystemSms.find(id)
    begin
      uri = URI('https://pgapi.vispl.in/fe/api/v1/send')
      res = Net::HTTP.post_form(uri,'username' => 'divine.trans', 'password' => 'NdEDI', 'from' => 'DIVIRE', 'to' => "91#{sms.mobile.last(10)}", 'unicode' => 'false', 'dltPrincipalEntityId' => '1701163222938992999', 'text' => "#{sms.text}", 'dltContentId' => "#{sms.template_id}")
      sent=true
      message=res.body
    rescue Exception => e
      sent = false
      message = e.to_s
      @pg_api_service_logger.info("processing sms-#{id} - 4")
    end
    sms.update(:response=>message, :sent=>sent)
    @pg_api_service_logger.info("processing sms-#{id} - 6")
    return true
  end
end
