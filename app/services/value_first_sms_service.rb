class ValueFirstSmsService

  def initialize(company, data)
    @company = company
    @data = data
  end

  def send_sms
    token_generation_response = _generate_token
    return false, token_generation_response[:error_message] unless token_generation_response[:success]
    bearer_token = token_generation_response[:bearer_token]

    sms_response = _sending_sms(bearer_token)

    _delete_token(bearer_token)

    [sms_response[:success] ? true : false, sms_response[:error_message]]
  end

  def _generate_token
    token_generation_url = "https://api.myvfirst.com/psms/api/messages/token?action=generate"
    authorization = { auth_type: 'basic_auth', user_id: @company.value_first_integration&.user_name, password: @company.value_first_integration&.token }
    response = _get_post_request_response(token_generation_url, authorization)
    response_body = JSON.parse(response[:response].body)

    {
      success: response[:success],
      bearer_token: response_body['token'],
      error_message: response[:error_message]
    }
  end

  def _delete_token(token)
    token_deletion_url = "https://api.myvfirst.com/psms/api/messages/token?action=delete&token=#{token}"
    authorization = { auth_type:'basic_auth', user_id: @company.value_first_integration&.user_name, password: @company.value_first_integration&.token }
    response = _get_post_request_response(token_deletion_url, authorization)

    {
      success: response[:success],
      error_message: response[:error_message],
      response: response[:response]
    }
  end

  def _sending_sms(token)
    sms_service_url = "https://api.myvfirst.com/psms/servlet/psms.JsonEservice"
    authorization = { auth_type: 'bearer_token', token: token }
    body = _get_value_first_payload
    response = _get_post_request_response(sms_service_url, authorization, body, "application/json")
    {
      success: response[:success],
      error_message: response[:error_message]
    }
  end

  def _get_post_request_response(url, authorization, body = nil, content_type = nil)
    success = true
    error_message = ''
    url = URI.parse(url)
    request = Net::HTTP::Post.new(url)
    request['Authorization'] = "Bearer #{authorization[:token]}" if authorization[:auth_type] == 'bearer_token'
    request.basic_auth(authorization[:user_id], authorization[:password]) if authorization[:auth_type] == 'basic_auth'
    request.body = body if body.present?
    request["Content-Type"] = content_type if content_type.present?

    begin
      http_object = Net::HTTP.new(url.host, url.port)
      http_object.use_ssl = true
      response = http_object.request(request)
      if response.code != "200"
        success = false
        error_message = "Error: #{response.code}"
      end
    rescue Exception => e
      success = false
      error_message = e
    end

    {
      success: success,
      error_message: error_message.to_s,
      response: response
    }
  end

  def _get_value_first_payload
    iso_code = "+91"
    mobile = "#{iso_code.remove('+')}#{@data[:data]}"

    json_payload = {
      "@VER": "1.2",
      "USER": {},
      "DLR": { "@URL": "" },
      "SMS": [
        {
          "@UDH": "0",
          "@CODING": "1",
          "@TEXT": @data[:message],
          "@TEMPLATEINFO": @data[:template],
          "@PROPERTY": "0",
          "@ID": "1",
          "ADDRESS": [
            {
              "@FROM": @company.value_first_integration&.sender,
              "@TO": mobile,
              "@SEQ": "1",
              "@TAG": "some client side random data"
            }
          ]
        }
      ]
    }

    JSON.generate(json_payload)
  end
end