module Api

  module ThirdPartyService

    class TeleteemtechController < PublicApiController

      before_action :create_service_api_log
      before_action :find_company, only: [:incoming_call]

      PROJECT_HASH = {
        "7941050784" => {project_id: 5804},
        "7941050785" => {project_id: 6703},
        "7941050785" => {project_id: 6826},
        "7941050786" => {project_id: 5679},
        "7941050795" => {project_id: 6700},
        "7941050796" => {project_id: 5823},
        "7941050799" => {project_id: 6824},
        "7941050799" => {project_id: 6825}
      }

      def incoming_call
        project_id =  (PROJECT_HASH.select{|sh| sh[teletech_params["channel"].last(10)]}.values.first[:project_id] rescue @company.default_project&.id)
        selected_source_id = 1107
        phone = teletech_params["caller"]&.last(10)
        agent_no = ((teletech_params["destination"]) rescue nil)
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
            sid: teletech_params["cdrid"],
            start_time: Time.zone.parse(teletech_params["starttime"]),
            from_number: phone,
            to_number: agent_no,
            end_time: Time.zone.parse(teletech_params["endtime"]),
            duration: teletech_params["duration"],
            direction: 'incoming',
            phone_number_sid: teletech_params["channel"].last(10),
            status: teletech_params["callstatus"],
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

      def teletech_params
        params.permit(
          :uuid,
          :call_to_number,
          :caller,
          :channel,
          :destination,
          :starttime,
          :endtime,
          :cdrid,
          :direction,
          :duration,
          :callstatus,
          :call_id,
          :agent_number
        )
      end

      def create_service_api_log
        ServiceApiLog.create(
          entry_type: 'teleteemtech',
          payload: params.except(:controller, :format).to_unsafe_h
        )
      end

    end
  end
end