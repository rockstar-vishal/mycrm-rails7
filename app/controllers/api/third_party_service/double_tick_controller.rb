class Api::ThirdPartyService::DoubleTickController < PublicApiController
	def log_messages
		File.open(Rails.root.join('log', 'doubletick-response.log'), 'a') do |file|
	      file.puts(params.to_json)
	    end
	    render json: {message: "Success"}, status: 200 and return
	end
end