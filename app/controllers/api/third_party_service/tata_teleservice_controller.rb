module Api

  module ThirdPartyService

    class TataTeleserviceController < PublicApiController

      before_action :create_service_api_log
      before_action :find_company, only: [:incoming_call, :auto_dailer_hangup]

      def callback
        @call_log = Leads::CallLog.find_by(sid: teleservices_params["call_id"])
        if @call_log.present?
          if @call_log.update(
            end_time: Time.zone.parse(teleservices_params["end_stamp"]),
            recording_url: teleservices_params["recording_url"],
            duration: teleservices_params["duration"],
            status: (teleservices_params["call_status"] == "answered"  ? 'ANSWER' : 'Missed'),
          )
            render :json=>{message: 'success'}, status: 200
          else
            render :json=>{:status=>"failed"}, status: 422
          end
        else
          render :json=>{message: 'callid not Found'}, status: 404
        end
      end

      def incoming_call
        telephony_sid = @company.cloud_telephony_sids.active.find_by(number: params[:call_to_number]&.last(10))
        project_id =  telephony_sid&.project_id || @company.default_project&.id
        selected_source_id = telephony_sid&.source_id || ::Source::INCOMING_CALL
        phone = teleservices_params["caller_id_number"]&.last(10)
        agent_no = (teleservices_params["call_status"] == "missed" ? params[:missed_agent].values.last["number"].last(10) : teleservices_params["answered_agent_number"]) rescue nil
        user_id = @company.users.find_by(mobile: agent_no&.last(10))&.id
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
            sid: teleservices_params["call_id"],
            start_time: Time.zone.parse(teleservices_params["start_stamp"]),
            from_number: phone,
            to_number: agent_no,
            end_time: Time.zone.parse(teleservices_params["end_stamp"]),
            recording_url: teleservices_params["recording_url"],
            duration: teleservices_params["duration"],
            direction: 'incoming',
            phone_number_sid: teleservices_params["call_to_number"],
            status: (teleservices_params["call_status"] == "missed"  ? 'Missed' : 'ANSWER'),
            call_type: 'Inbound'
          )
          render json: {staus: 200}
        else
          render :json=>{:status=>"Failure"}
        end
      end
      
      def auto_dailer_hangup
        telephony_sid = @company.cloud_telephony_sids.active.find_by(number: params[:call_to_number]&.last(10))
        project_id =  telephony_sid&.project_id || @company.default_project&.id
        selected_source_id = telephony_sid&.source_id || ::Source::INCOMING_CALL
        phone = teleservices_params["caller_id_number"]&.last(10)
        @lead = @company.leads.active_for(@company).where("RIGHT(REPLACE(mobile,' ', ''), 10) LIKE ?", phone&.last(10)).last
        agent_no = (teleservices_params["call_status"] == "missed" ? params[:missed_agent].values.last["number"].last(10) : teleservices_params["answered_agent_number"]) rescue nil
        user_id = @company.users.where("RIGHT(REPLACE(mobile,' ', ''), 10) LIKE ?", agent_no&.last(10)).last&.id

        if @lead.present?
          call_logs = @lead.call_logs.build(
            caller: 'Lead',
            direction: 'outgoing',
            sid: teleservices_params["call_id"],
            start_time: Time.zone.parse(teleservices_params["start_stamp"]),
            to_number: phone,
            from_number: agent_no,
            duration: teleservices_params["duration"],
            status: teleservices_params["call_status"],
            third_party_id: 'tatatele',
            recording_url: teleservices_params["recording_url"],
            user_id: @lead.user_id
          )
          if call_logs.save
            render :json=>{:status=>"Success"}, status: 200
          else
            render :json=>{:status=>"Failed"}, status: 422
          end
        else
          @lead = @company.leads.new(
            name: '--',
            mobile: phone,
            project_id: project_id,
            status_id: @company.new_status_id,
            source_id: selected_source_id,
            user_id: user_id
          )
          if @lead.save
            call_logs = @lead.call_logs.build(
              caller: 'Lead',
              direction: 'outgoing',
              sid: teleservices_params["call_id"],
              start_time: Time.zone.parse(teleservices_params["start_stamp"]),
              to_number: phone,
              from_number: agent_no,
              status: teleservices_params["call_status"],
              third_party_id: 'tatatele',
              recording_url: teleservices_params["recording_url"],
              user_id: user_id
            )
            call_logs.save
            render :json=>{:status=>"Success"}, status: 200
          else
            render json: {status: 'Failed'}, status: 422
          end
        end
      end

      private

      def find_company
        @company = Company.find_by(uuid: params["uuid"]) rescue nil
        if @company.blank?
          render json: {status: false, message: "Invalid IVR"}, status: 400 and return
        end
      end

     def teleservices_params
        params.permit(
          :uuid,
          :call_to_number,
          :caller_id_number,
          :start_stamp,
          :answer_stamp,
          :end_stamp,
          :hangup_cause,
          :billsec,
          :digits_dialed,
          :direction,
          :duration,
          :answered_agent,
          :answered_agent_name,
          :answered_agent_number,
          :missed_agent,
          :call_flow,
          :broadcast_lead_fields,
          :recording_url,
          :call_status,
          :call_id,
          :outbound_sec,
          :agent_ring_time,
          :billing_circle,
          :call_connected,
          :aws_call_recording_identifier,
          :customer_no_with_prefix
        )
      end

      def create_service_api_log
        ServiceApiLog.create(
          entry_type: 'tatateleservice',
          payload: params.except(:controller, :format)
        )
      end

    end

  end

end
