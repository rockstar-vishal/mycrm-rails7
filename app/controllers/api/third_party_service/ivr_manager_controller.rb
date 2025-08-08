module Api
  module ThirdPartyService
    class IvrManagerController < PublicApiController
      before_action :find_company

      DATA_HASH = {
        "8238087100" => "a3b0cc86-f9ae-40f8-95d7-4ad28bd64799",
        "8238084445" => "a3b0cc86-f9ae-40f8-95d7-4ad28bd64799",
        "9998881927" => "a3b0cc86-f9ae-40f8-95d7-4ad28bd64799"
      }

      SETTING_HASH = {
        "8238084445" => { project_id: 6395 },
        "9998881927" => { project_id: 6396 }
      }

      def incoming_call
        project_id = (SETTING_HASH.select{|sh| sh[ivr_params[:landingNumber]]}.values.first[:project_id] rescue @company.default_project&.id)
        user_id = @company.users.active.find_by(mobile: ivr_params[:destinationNumber])&.id || @company.users.active.superadmins.first.id
        @lead = @company.leads.where("RIGHT(REPLACE(mobile,' ', ''), 10) LIKE ?", ivr_params[:sourceNumber].last(10)).last
        if @lead.present?
          @lead.update(project_id: project_id)
        else
          @lead = @company.leads.build(
            name: '--',
            mobile: ivr_params[:sourceNumber],
            source_id: 2,
            status_id: @company.new_status_id,
            user_id: user_id,
            project_id: project_id
          )
        end
        if @lead.save
          call_logs = @lead.call_logs.build(
            caller: 'Lead',
            direction: 'incoming',
            sid: ivr_params[:callId],
            start_time: ivr_params[:startTime],
            from_number: @lead.mobile,
            to_number: ivr_params[:destinationNumber],
            third_party_id: 'ivrmanager',
            phone_number_sid: ivr_params[:landingNumber]
          )
          call_logs.save
          render :json=>{:status=>"Success"}, status: 200 and return
        else
          render json: {status: false, :message=>"Lead not created", :debug_message=>@lead.errors.full_messages.join(","), :data=>{}}, status: 422 and return
        end
      end

      def hangup
        @call_log = Leads::CallLog.where(sid: ivr_params[:callId]).last
        user_id = @company.users.active.find_by(mobile: ivr_params[:destinationNumber])&.id || @company.users.active.superadmins.first.id
        if @call_log.update(
          user_id: user_id,
          end_time: ivr_params[:endTime],
          to_number: ivr_params[:destinationNumber],
          recording_url: "#{ivr_params[:recordingUrl]}",
          status: ivr_params[:duration].to_i > 0 ? 'ANSWER': 'MISSED',
          duration: ivr_params[:duration],
          call_type: 'inbound'
        )
          render :json=>{:status=>"Success"}
        else
          render :json=>{:status=>"Failure"}
        end
      end

      private

      def find_company
        @company = Company.find_by(uuid: DATA_HASH[params["landingNumber"]]) rescue nil
        if @company.blank?
          render json: {status: false, message: "Invalid IVR"}, status: 400 and return
        end
      end

      def ivr_params
        params.permit(
          :sourceNumber,
          :destinationNumber,
          :endTime,
          :startTime,
          :callId,
          :recordingUrl,
          :duration,
          :landingNumber
        )
      end
    end
  end
end