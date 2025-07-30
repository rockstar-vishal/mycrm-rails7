module Api

  module ThirdPartyService

    class CallLogsController < PublicApiController 

      before_action :find_company


      def incoming_call_hangup
        selected_source_id = 2
        user = @company.users.find_by(mobile: params["DialWhomNumber"]&.last(10)) || @company.users.active.superadmins.first
        project_id =  @company.default_project&.id
        phone = params["SourceNumber"]&.last(10)
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
            sid: params["CallSid"],
            start_time: params["StartTime"],
            from_number: @lead.mobile,
            to_number: params["DialWhomNumber"],
            end_time: params["EndTime"],
            recording_url: params["CallRecordingUrl"],
            duration: params["CallDuration"],
            direction: 'incoming',
            status: params["Status"] 
          )
          render json: {staus: 200}
        else
          render :json=>{:status=>"Failure"}
        end
      end

      def find_company
        @company = Company.find_by(uuid: params[:uuid]) rescue nil
        if @company.blank?
          render json: {status: false, message: "Invalid IVR"}, status: 400 and return
        end
      end

    end

  end

end