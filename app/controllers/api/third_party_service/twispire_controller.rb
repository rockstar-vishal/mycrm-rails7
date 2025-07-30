module Api

  module ThirdPartyService

    class TwispireController < PublicApiController

      before_action :create_service_api_log
      before_action :find_company, only: [:incoming_call]

      def incoming_call
        telephony_sid = @company.cloud_telephony_sids.active.find_by(number: twispire_params["did_number"]&.last(10))
        project_id =  telephony_sid&.project_id || @company.default_project&.id
        selected_source_id = (telephony_sid&.source_id rescue 2)
        phone = twispire_params["caller_id_number"]&.last(10)
        agent_no = ((twispire_params["agent_number"]) rescue nil)
        user_id = @company.users.find_by(mobile: agent_no&.last(10))&.id || @company.users.active.superadmins.first
        @leads = @company.leads.active_for(@company).where(:project_id=>project_id).where("( mobile LIKE ?)", "%#{phone.last(10) if phone.present?}%")
        if @leads.present?
          @lead = @leads.last
        else
          @lead = @company.leads.new(
            mobile: phone,
            project_id: project_id
          )
        end
        @lead.assign_attributes(
          name: @lead.name || '--',
          status_id: @lead.status_id || @company.new_status_id,
          source_id:  @lead.source_id || selected_source_id,
          user_id: @lead.user_id || user_id
        )
        if @lead.save
          @lead.call_logs.create(
            user_id: user_id,
            caller: 'Lead',
            sid: twispire_params["call_id"],
            start_time: Time.zone.parse(twispire_params["start_stamp"]),
            from_number: phone,
            to_number: agent_no,
            end_time: Time.zone.parse(twispire_params["end_stamp"]),
            duration: twispire_params["duration"],
            recording_url: twispire_params["recording_url"],
            direction: 'incoming',
            phone_number_sid: twispire_params["did_number"],
            status: (twispire_params["agent_number"].present? ? 'ANSWER' : 'Missed'),
            call_type: 'Inbound'
          )
          render json: {staus: 200}
        else
          render :json=>{:status=>"Failure"}
        end
      end

      private

      def find_company
        @company = Company.find_by(uuid: params["uuid"]) rescue nil
        if @company.blank?
          render json: {status: false, message: "Invalid IVR"}, status: 400 and return
        end
      end

     def twispire_params
        params.permit(
          :uuid,
          :call_to_number,
          :caller_id_number,
          :start_stamp,
          :answer_stamp,
          :end_stamp,
          :direction,
          :duration,
          :call_status,
          :call_id,
          :agent_answer_time,
          :extension,
          :did_number,
          :recording_url,
          :agent_number
        )
      end

      def create_service_api_log
        ServiceApiLog.create(
          entry_type: 'twispire',
          payload: params.except(:controller, :format)
        )
      end

    end
  end
end