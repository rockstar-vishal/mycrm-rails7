module Api

  module ThirdPartyService

    class SlashRtcserviceController < PublicApiController
      before_action :create_service_api_log
      before_action :find_company, except: [:callback]

      def callback
        @call_log = Leads::CallLog.where(sid: slashrtc_params[:refrence_id]).last
        if @call_log.update(
          start_time: Time.zone.parse(slashrtc_params[:call_start_date_time]),
          end_time: (Time.zone.parse(slashrtc_params[:call_end_date_time]) rescue nil),
          duration: slashrtc_params[:agent_talktime_sec],
          recording_url: slashrtc_params[:media_url],
          status: slashrtc_params[:agent_talktime_sec].to_i > 0 ? 'ANSWER' : 'Missed'
        )
          render :json=>{:status=>"Success"}
        else
          render :json=>{:status=>"Failure"}
        end
      end

      def incoming_call
        phone = slashrtc_params[:Phone]
        @user = @company.users.active.find_by(email: slashrtc_params[:employee_id]) || @company.users.active.superadmins.first
        @leads = @company.leads.where("mobile != '' AND mobile IS NOT NULL AND RIGHT(REPLACE(mobile, ' ', ''), 10) LIKE ?", "%#{phone.last(10)}%")
        project_id = @company.default_project&.id
        source_id = @company.sources.find_id_from_name(slashrtc_params[:source]) || 2
        enquiry_sub_source_id = (@company.sub_sources.find_id_from_name(slashrtc_params[:sub_source]) rescue nil)
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
          source_id:  @lead.source_id || source_id,
          user_id: @lead.user_id || @user.id,
          enquiry_sub_source_id: enquiry_sub_source_id
        )
        if @lead.save
          call_log = @lead.call_logs.build(
            caller: 'Lead',
            direction: 'incoming',
            sid: slashrtc_params[:refrence_id],
            start_time: slashrtc_params[:call_start_date_time],
            to_number: slashrtc_params[:Extension] || @user.mobile,
            from_number: @lead.mobile,
            third_party_id: 'slashrtc'
          )
          call_log.save
          render :json=>{:status=>"Success"}, status: 200 and return
        else
          render json: {status: false, :message=>"Lead not created", :debug_message=>@lead.errors.full_messages.join(","), :data=>{}}, status: 422 and return
        end
      end
      
      def hangup
        @call_log = Leads::CallLog.where(sid: slashrtc_params[:refrence_id]).last
        @user = @company.users.active.find_by(email: slashrtc_params[:employee_id]) || @company.users.active.superadmins.first
        if @call_log.update(
          user_id: @user.id,
          end_time: slashrtc_params[:call_end_date_time],
          duration: slashrtc_params[:agent_talktime_sec],
          recording_url: slashrtc_params[:media_url],
          status: slashrtc_params[:agent_talktime_sec].to_i > 0 ? 'ANSWER' : 'Missed',
          call_type: 'inbound'
        )
          render :json=>{:status=>"Success"}
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

      def slashrtc_params
        params.permit(
          :Phone,
          :Extension,
          :employee_id,
          :call_start_date_time,
          :call_end_date_time,
          :mode_of_calling,
          :refrence_id,
          :media_url,
          :agent_talktime_sec,
          :source,
          :sub_source
        )
      end

      def create_service_api_log
        ServiceApiLog.create(
          entry_type: 'slashrtcservice',
          payload: params.except(:controller, :format)
        )
      end
    end
  end
end