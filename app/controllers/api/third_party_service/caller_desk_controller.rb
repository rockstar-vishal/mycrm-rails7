module Api

  module ThirdPartyService

    class CallerDeskController < PublicApiController

      before_action :find_company, except: [:call_logs]

      DATA_HASH = {
        "8884898765" => '0714749d-e8b6-45cf-989b-b402c34eb574',
        "9212222900" => '0714749d-e8b6-45cf-989b-b402c34eb574',
        "7838737374" => '32f6c7af-842b-4a60-81aa-de00186ef4dc',
        "08069247832" => 'bab52de2-8cda-4aff-b9c2-1940c3d59e12',
        "8929676861" => 'bab52de2-8cda-4aff-b9c2-1940c3d59e12'
      }

      SETTING_HASH = {
        "7838737374" => {source_id: 536}
      }

      def call_logs
        @call_log = Leads::CallLog.where(sid: call_params["CallSid"]).last
        if @call_log.update(
          start_time: Time.zone.parse(call_params["StartTime"]),
          end_time: (Time.zone.parse(call_params["EndTime"]) rescue nil),
          recording_url: call_params["CallRecordingUrl"],
          duration: call_params["CallDuration"],
          status: call_params["Status"]
        )
          render :json=>{:status=>"Success"}
        else
          render :json=>{:status=>"Failure"}
        end
      end

      def hangup
        selected_source_id = (SETTING_HASH.select{|sh| sh[call_params["DestinationNumber"]]}.values.first[:source_id] rescue 2)
        user = @company.users.find_by(mobile: call_params["DialWhomNumber"]&.last(10)) || @company.users.active.superadmins.first
        project_id =  (user.caller_desk_project_id || @company.default_project&.id)
        phone = call_params["SourceNumber"]&.last(10)
        user_id = user&.id
        @leads = @company.leads.active_for(@company).where(:project_id=>project_id).where("( mobile LIKE ?)", "%#{phone.last(10) if phone.present?}%")
        if @leads.present?
          @lead = @leads.last
        else
          @lead = @company.leads.new(
            mobile: phone,
            project_id: project_id,
          )
        end
        @lead.assign_attributes(
          name: @lead.name || '--',
          status_id: @lead.status_id || @company.new_status_id,
          source_id:  selected_source_id,
          user_id: @lead.user_id || user_id
        )
        if @lead.save
          @lead.call_logs.create(
            user_id: @lead.user_id,
            caller: 'Lead',
            sid: call_params["CallSid"],
            start_time: call_params["StartTime"],
            from_number: @lead.mobile,
            to_number: call_params["DialWhomNumber"],
            end_time: call_params["EndTime"],
            recording_url: call_params["CallRecordingUrl"],
            duration: call_params["CallDuration"],
            direction: 'incoming',
            status: call_params["Status"],
            third_party_id: 'callerdesk'
          )
          render json: {staus: 200}
        else
          render :json=>{:status=>"Failure"}
        end
      end

      private

      def find_company
        @company = Company.find_by(uuid: DATA_HASH[params["DestinationNumber"]]) rescue nil
        if @company.blank?
          render json: {status: false, message: "Invalid IVR"}, status: 400 and return
        end
      end

      def call_params
        params.permit(
          :SourceNumber,
          :DestinationNumber,
          :DialWhomNumber,
          :CallDuration,
          :Status,
          :StartTime,
          :EndTime,
          :CallRecordingUrl,
          :CallSid,
          :Direction,
          :TalkDuration
        )
      end

    end

  end

end
