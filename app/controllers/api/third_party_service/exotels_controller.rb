module Api

  module ThirdPartyService

    class ExotelsController < PublicApiController

      before_action :find_lead, only: [:incoming_call_back]
      before_action :find_company, only: :marketing_incoming_call

      def callback
        @call_log = Leads::CallLog.find_by(sid: exotel_params["CallSid"])
        if @call_log.update(
          end_time: exotel_params["EndTime"],
          recording_url: exotel_params["RecordingUrl"],
          duration: exotel_params["ConversationDuration"],
          direction: exotel_params["Direction"],
          phone_number_sid: exotel_params["PhoneNumberSid"],
          status: exotel_params["Status"],
          executive_call_duration: (params["Legs"]["0"]["OnCallDuration"] rescue ''),
          executive_call_status: (params["Legs"]["0"]["Status"] rescue ''),
          lead_call_duration: (params["Legs"]["1"]["OnCallDuration"] rescue ''),
          lead_call_status: (params["Legs"]["1"]["Status"] rescue ''),
        )
          company = @call_log.lead&.company
          if exotel_params[:RecordingUrl].present?
            begin
              recording_data = access_exotel_recording(exotel_params[:RecordingUrl], company)
              Tempfile.create(["recording_#{@call_log.sid}"]) do |temp_file|
                temp_file.binmode
                temp_file.write(recording_data)
                temp_file.rewind

                @call_log.recorded_audio = File.open(temp_file.path)
                @call_log.recorded_audio_content_type = 'audio/mp3'
                @call_log.save
              end
            rescue => e
              render json: { status: "Failure", error: e.message } and return
            end
          end
          render :json=>{:status=>"Success"}
        else
          render :json=>{:status=>"Failure"}
        end
      end

      def incoming_call
        find_company
        Rails.logger.info(" --- DEBUG: Company found: #{@company&.id} ----")
        @call_log = Leads::CallLog.where(to_number: exotel_params["CallFrom"], user_id: @company.users.ids).last
        Rails.logger.info(" --- DEBUG: Call log found: #{@call_log&.id} ----")
        if @call_log.present?
          @lead = @company.leads.find_by(id: @call_log.lead_id)
        else
          @lead = @company.leads.find_by(mobile: exotel_params["CallFrom"])
        end
        Rails.logger.info(" --- DEBUG: Lead found: #{@lead&.id} ----")
        numbers = []
        if @lead.present?
          num = @lead&.user&.mobile
          numbers << num if num
          Rails.logger.info(" --- DEBUG: Lead user mobile: #{num} ----")
        end
        if @call_log.present?
          from_num = @call_log.from_number
          numbers << from_num if from_num.present?
          Rails.logger.info(" --- DEBUG: Call log from number: #{from_num} ----")
        end
        if numbers.any?(&:present?)
          Rails.logger.info(" --- Reached 1 ---- #{numbers} ----")
          render text: numbers.compact.join(","), content_type: 'text/plain', status: 200
        else
          Rails.logger.info(" --- Reached 2 ---- #{default_numbers} ---- ")
          render text: default_numbers.join(","), content_type: 'text/plain', status: 200
        end
      end

      def incoming_connection
        IncomingCall.create(
          from_number: exotel_params["CallFrom"],
          start_time: exotel_params["StartTime"],
          phone_number_sid: exotel_params["CallTo"]
        )
        render json: {staus: 200}
      end

      def incoming_call_back
        if @lead.present?
          user_id = @lead.company.users.find_by(mobile: exotel_params["DialWhomNumber"]&.last(10))&.id || @lead.user_id
          @call_log = @lead.call_logs.create(
            user_id: user_id,
            caller: 'Lead',
            sid: exotel_params["CallSid"],
            start_time: exotel_params["StartTime"],
            from_number: exotel_params["CallFrom"],
            to_number: exotel_params["DialWhomNumber"],
            end_time: (Time.zone.parse(exotel_params["StartTime"]) + exotel_params["DialCallDuration"].to_i),
            recording_url: exotel_params["RecordingUrl"],
            duration: exotel_params["DialCallDuration"],
            direction: exotel_params["Direction"],
            phone_number_sid: exotel_params["CallTo"],
            status: exotel_params["DialCallStatus"],
            call_type: exotel_params["CallType"]
          )
          @company = @lead.company
          if exotel_params[:RecordingUrl].present? && @call_log.present?
            begin
              recording_data = access_exotel_recording(exotel_params[:RecordingUrl], @company)
              Tempfile.create(["recording_#{@call_log.sid}"]) do |temp_file|
                temp_file.binmode
                temp_file.write(recording_data)
                temp_file.rewind

                @call_log.recorded_audio = File.open(temp_file.path)
                @call_log.recorded_audio_content_type = 'audio/mp3'
                @call_log.save
              end
            rescue => e
              render json: { status: "Failure", error: e.message } and return
            end
          end
        else
          IncomingCall.create(
            caller: 'Lead',
            sid: exotel_params["CallSid"],
            from_number: exotel_params["CallFrom"],
            to_number: exotel_params["DialWhomNumber"],
            start_time: Time.zone.parse(exotel_params["StartTime"]),
            end_time: (Time.zone.parse(exotel_params["StartTime"]) + exotel_params["DialCallDuration"].to_i),
            recording_url: exotel_params["RecordingUrl"],
            duration: exotel_params["DialCallDuration"],
            direction: exotel_params["Direction"],
            phone_number_sid: exotel_params["To"],
            status: exotel_params["DialCallStatus"],
            call_type: exotel_params["CallType"]
          )
        end
      end

      def marketing_incoming_call
        project_id =  @exotel.project_id || @company.default_project&.id
        phone = exotel_params["CallFrom"]&.last(10)
        if @exotel.is_round_robin_enabled?
          user_id = @exotel.find_round_robin_user
        end
        if exotel_params["DialWhomNumber"].present?
          user_id = @company.users.find_by(mobile: exotel_params["DialWhomNumber"]&.last(10))&.id
        end
        if @company.setting.global_validation.present?
          @leads = @company.leads.where("( RIGHT(mobile, 10) LIKE ?)", "%#{phone.last(10) if phone.present?}%")
        else
          @leads = @company.leads.active_for(@company).where(:project_id=>project_id).where("( RIGHT(mobile, 10) LIKE ?)", "%#{phone.last(10) if phone.present?}%")
        end
        if @leads.present?
          @lead = @leads.last
        else
          @lead = @company.leads.new(
            mobile: exotel_params["CallFrom"],
            project_id: project_id
          )
        end
        @lead.assign_attributes(
          name: @lead.name || '--',
          status_id: @lead.status_id || @company.new_status_id,
          source_id:  @lead.source_id || @exotel.source_id,
          user_id: @lead.user_id || user_id
        )
        @lead.cannot_send_notification = true
        if @lead.save
          @call_log = @lead.call_logs.create(
            user_id: user_id,
            caller: 'Lead',
            sid: exotel_params["CallSid"],
            start_time: exotel_params["StartTime"],
            from_number: exotel_params["CallFrom"],
            to_number: exotel_params["DialWhomNumber"],
            end_time: (Time.zone.parse(exotel_params["StartTime"]) + exotel_params["DialCallDuration"].to_i),
            recording_url: exotel_params["RecordingUrl"],
            duration: exotel_params["DialCallDuration"],
            direction: exotel_params["Direction"],
            phone_number_sid: exotel_params["CallTo"],
            status: exotel_params["DialCallStatus"],
            call_type: exotel_params["CallType"]
          )
          if exotel_params[:RecordingUrl].present? && @call_log.present?
            begin
              recording_data = access_exotel_recording(exotel_params[:RecordingUrl], @company)
              @call_log.direction = "incoming"
              Tempfile.create(["recording_#{@call_log.sid}"]) do |temp_file|
                temp_file.binmode
                temp_file.write(recording_data)
                temp_file.rewind

                @call_log.recorded_audio = File.open(temp_file.path)
                @call_log.recorded_audio_content_type = 'audio/mp3'
                @call_log.save
              end
            rescue => e
              render json: { status: "Failure", error: e.message } and return
            end
          end
          render json: {staus: 200}
        else
          render :json=>{:status=>"Failure"}
        end
      end

      def notify_users
        @exotel_sid = ExotelSid.find_by(number: exotel_params["CallTo"])
        @user = @exotel_sid.company.users.find_by(mobile: exotel_params["DialWhomNumber"]&.last(10))
        if @user.present?
          @user.notify_incoming_call(exotel_params["CallFrom"])
        end
      end

      def access_exotel_recording(url, company)
        uri = URI(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Get.new(uri)
        username = company.exotel_integration_integration_key
        password = company.exotel_integration_token
        request.basic_auth(username, password)

        response = http.request(request)

        if response.code == '200'
          recording_data = response.body
          return recording_data
        else
          return nil
        end
      end

      private

      def exotel_params
        params.permit(
          :CallSid,
          :StartTime,
          :EndTime,
          :Direction,
          :RecordingUrl,
          :ConversationDuration,
          :Status,
          :PhoneNumberSid,
          :CallFrom,
          :CallTo,
          :CallStatus,
          :StartTime,
          :DialCallDuration,
          :DialWhomNumber,
          :DialCallStatus,
          :To,
          :CallType,
          :AgentEmail
        )
      end

      def find_lead
        @call_log = Leads::CallLog.where(to_number: exotel_params["CallFrom"]).last
        if @call_log.present?
          @lead = Lead.find_by(id: @call_log.lead_id)
        else
          @lead = Lead.find_by(mobile: exotel_params["CallFrom"])
        end
      end

      def default_numbers
        default_executive_ph_nos = []
        Rails.logger.info(" --- DEBUG: Looking for ExotelSid with number: #{exotel_params["To"]} ----")
        @exotel_sids = ExotelSid.active.find_by(number: exotel_params["To"])
        Rails.logger.info(" --- DEBUG: ExotelSid found: #{@exotel_sids&.id} ----")
        if @exotel_sids.present?
          default_executive_ph_nos = @exotel_sids.default_numbers.reject(&:blank?)
          Rails.logger.info(" --- DEBUG: Default numbers: #{default_executive_ph_nos} ----")
        end
        default_executive_ph_nos
      end

      def find_company
        @exotel = ExotelSid.active.inbound_numbers.find_by(number: exotel_params["CallTo"])
        @company = @exotel.company
      end

    end

  end

end
