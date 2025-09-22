require 'uri'
require "net/http"

class SmsService

  class << self

    def send_sv_otp(otp)
      begin
        sv=otp.company.sv_form
        url = sv.otp_url
        variables = prepare_variables(sv.other_data, otp.validatable_data, otp.code)
        rendered_template = render_template(url, variables)
        if sv.request_method=="post"
          if rendered_template.include?("headers")
            base_url, payload, headers = parse_msg91_url(rendered_template, otp)
            response = RestClient.post(base_url, payload.to_json, headers)
            return true, response
          else
            response = ExotelSao.secure_post("#{rendered_template}", {})
            sent = true
            message= response["message"]["message-id"] rescue nil
          end
          return true, response
        else
          url = URI(rendered_template)
          http = Net::HTTP.new(url.host, url.port)
          request = Net::HTTP::Get.new(url)
          unless url.scheme == "http"
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          end
          response = http.request(request)
          response_body = JSON.parse response.body
          return true, {code: response.code, body: response_body}
        end
      rescue Exception => e
        return false, e.to_s
      end
    end

    def parse_msg91_url(otp_form_url, otp)
      decoded_raw = CGI.unescape(otp_form_url)
      base_url    = decoded_raw[/^https:\/\/control\.msg91\.com\/api\/v5\/flow/]
      payload_str = decoded_raw[/payload\s*=\s*\{.*\}\]/].to_s.sub("payload =", "").strip
      headers_str = decoded_raw[/headers\s*=\s*\{.*\}/].to_s.sub("headers =", "").strip

      mobile_number = payload_str[/mobiles:\s*(\d+)/, 1]
      otp_code      = payload_str[/var1:\s*(\d+)/, 1]
      mobile_number = normalize_mobile(mobile_number)

      payload = {
        template_id: payload_str[/template_id:\s*([a-z0-9]+)/, 1],
        recipients: [{ mobiles: mobile_number, var1: otp_code }]
      }
      headers = {}
      headers_str.scan(/(\w[\w\-]*)\s*=>\s*([^,}\s]+)/) do |k, v|
        headers[k] = v
      end

      [base_url, payload, headers]
    end

    def normalize_mobile(number)
      return nil unless number
      return "91#{number}" if number.length == 10
      number.start_with?("91") ? number : "91#{number}"
    end

    def send_otp(otp)
      begin
        url = otp.company.sms_integration.url
        if url == "https://mdssend.in"
          text = "Your OTP for Gami Group is #{otp.code}"
          response = ExotelSao.secure_post("#{url}/api.php?username=GamiOTP&apikey=xMLSJp12i2ZT&senderid=GAMIGP&route=OTP&mobile=#{otp.validatable_data}&text=#{text}", {})
        else
          text = "Your One Time Otp Is #{otp.code}"
          response = ExotelSao.secure_post("#{url}?From=02071178100&To=#{otp.validatable_data}&Body=#{text}", {})
          message= response["SMSMessage"]["Sid"] rescue nil
        end
        sent = true
        return true, response
      rescue Exception => e
        return false, e.to_s
      end
    end

    def send_sonam_otp(otp)
      begin
        otp_code=otp.code
        url=otp.company.sms_integration.url
        site_link="https://sonamgroup.com"
        url_encoded_sms_text = URI.encode_www_form_component(site_link)
        response=ExotelSao.secure_post("#{url}/websms/api/http/index.php?username=sonam&apikey=BE72C-D2A55&apirequest=Template&route=ServiceExplicit&sender=SONAMB&mobile=#{otp.validatable_data}&TemplateID=1207168024429525769&Values=#{otp_code},#{url_encoded_sms_text}", {})
        sent = true
        message= response["message"]["message-id"] rescue nil
        return true, response
      rescue Exception => e
        puts e.to_s
        return false, e.to_s
      end
    end

    def send_ravima_otp(otp)
      begin
        otp_code=otp.code
        url=otp.company.sms_integration.url

        url = URI("#{url}/api/mt/SendSMS?user=Apiravimaventures&password=Ravimaventures987&senderid=RAVEMA&channel=Trans&DCS=0&flashsms=0&number=#{otp.validatable_data}&text=#{otp_code} is the Onetime Password (OTP) for your booking form request. To process your request, kindly enter the OTP. RAVIMA VENTURE&route=8&dlttemplateid=1707168759842461466")

        http = Net::HTTP.new(url.host, url.port);
        request = Net::HTTP::Get.new(url)

        response = http.request(request)
      rescue Exception => e
        return false, e.to_s
      end
    end

    def prepare_variables(other_data, mobile_number, otp_code)
      variables = other_data.map do |key, value|
        if value == 'mobile'
          [key, mobile_number]
        elsif value == 'otp'
          [key, otp_code]
        else
          [key, value]
        end
      end.to_h
      return variables
    end

    def render_template(template_text, variables)
      variables.each do |key, value|
        template_text.gsub!("{{#{key}}}", value.to_s)
      end
      return template_text
    end
  end
end
