require 'net/http'
require 'uri'
require 'json'

class ExotelSao

  class << self

    def secure_post url, request_body
      response = RestClient.post(url, request_body)
      response = JSON.parse(response)
    end

    def secure_post_with_headers(url, request_body, headers)
      begin
        uri = URI.parse(url)
        request = Net::HTTP::Post.new(uri)
        request.content_type = "application/json"
        request["Accept"] = "application/json"
        request["Authorization"] = headers['Authorization']
        request["x-api-key"] = headers['x-api-key']
        request.body = JSON.dump(request_body)

        req_options = {
          use_ssl: uri.scheme == "https",
        }
        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
          http.request(request)
        end
        if response.kind_of?(Net::HTTPSuccess)
          response = JSON.parse(response.body)["success"] || JSON.parse(response.body)["error"]
        end
        response
      rescue => e
        e
      end
    end

    def secure_post_with_auth_headers(url, request_body, headers)
      begin
        uri = URI.parse(url)
        request = Net::HTTP::Post.new(uri)
        request.content_type = "application/json"
        request["Accept"] = "application/json"
        request["Authorization"] = headers['Authorization']
        request.body = JSON.dump(request_body)

        req_options = {
          use_ssl: uri.scheme == "https",
        }
        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
          http.request(request)
        end
        if response.kind_of?(Net::HTTPSuccess)

          response = JSON.parse(response.body)["success"] || JSON.parse(response.body)["error"]
        end
        response
      rescue => e
        e
      end
    end

    def secure_post_with_auth_headers_response(url, request_body, headers)
      begin
        uri = URI.parse(url)
        request = Net::HTTP::Post.new(uri)
        request.content_type = "application/json"
        request["Accept"] = "application/json"
        request["Authorization"] = headers['Authorization']
        request.body = JSON.dump(request_body)

        req_options = {
          use_ssl: uri.scheme == "https",
        }
        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
          http.request(request)
        end
        if response.kind_of?(Net::HTTPSuccess)
          response = JSON.parse(response.body)
        end
        response
      rescue => e
        e
      end
    end

  end

end