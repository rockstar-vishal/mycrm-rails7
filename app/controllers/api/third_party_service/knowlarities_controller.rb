module Api

  module ThirdPartyService

    class KnowlaritiesController < PublicApiController
      before_action :create_service_api_log
      before_action :find_company, only: :incoming_call

      SETTING_HASH = {
        "8291935811"=> {source_id: 10},
        "8291935822" => {source_id: 102},
        "9513166762" => {source_id: 120},
        "9513166763" => {source_id: 120},
        "7620400800" => {source_id: 10},
        "7303520051" => {source_id: 301},
        "7506738607" => {source_id: 478},
        "8448449233" => {source_id: 533},
        "7304633333" => {source_id: 532},
        "9582370390" => {source_id: 535},
        "7303203333" => {source_id: 534},
        "8929338435" => {source_id: 537}
      }

      PROJECT_HASH = {
        "9513166762" => {project_id: 833},
        "9513166763" => {project_id: 822},
        "8657500928" => {project_id: 4388},
        "7506724147" => {project_id: 4387},
        "7045027208" => {project_id: 4385},
        "7620400800" => {project_id: 4383},
        "7303520051" => {project_id: 4383},
        "9930491031" => {project_id: 4623},
        "8484929274" => {project_id: 4753},
        "8484929286" => {project_id: 4753},
        "8484929424" => {project_id: 4753},
        "8484929434" => {project_id: 4753},
        "8484929464" => {project_id: 4752},
        "8484929470" => {project_id: 4752},
        "8484929472" => {project_id: 4751},
        "8484929482" => {project_id: 4751},
        "8484929487" => {project_id: 4751},
        "8484929493" => {project_id: 4751},
        "7996345626" => {project_id: 4751},
        "7996342999" => {project_id: 4751},
        "7996346555" => {project_id: 4753},
        "7996341777" => {project_id: 4753},
        "7996185333" => {project_id: 4752},
        "7996186111" => {project_id: 4752},
        "9821367774" => {project_id: 4869},
        "9015757777" => {project_id: 2346},
        "7506738607" => {project_id: 3772},
        "8448449233" => {project_id: 4776},
        "7304633333" => {project_id: 4776},
        "9582370390" => {project_id: 4777},
        "7303203333" => {project_id: 4777},
        "8929338435" => {project_id: 4778},
        "8879772277" => {project_id: 5316},
        "7042902233" => {project_id: 7003}
      }

      def callback
        @call_log = Leads::CallLog.find_by(sid: knowlarities_params["callid"])
        if @call_log.present?
          if @call_log.update(
            start_time: (Time.zone.parse(knowlarities_params[:call_date]) + Time.zone.parse(knowlarities_params[:call_time]).seconds_since_midnight rescue Time.zone.now),
            end_time: Time.zone.now,
            executive_call_duration: knowlarities_params["agent_call_duration"],
            lead_call_duration:  knowlarities_params["customer_call_duration"],
            recording_url: knowlarities_params["recording_url"],
            duration: knowlarities_params["customer_call_duration"],
            status: (knowlarities_params["customer_status"] == "Connected"  ? 'ANSWER' : 'Missed'),
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
        project_id =  (PROJECT_HASH.select{|sh| sh[knowlarities_params["dispnumber"].last(10)]}.values.first[:project_id] rescue @company.default_project&.id)
        phone = knowlarities_params["caller_id"]&.last(10)
        user_id = @company.users.find_by(mobile: knowlarities_params["destination"]&.last(10))&.id
        @leads = @company.leads.active_for(@company).where(:project_id=>project_id).where("( mobile LIKE ?)", "%#{phone.last(10) if phone.present?}%")
        selected_source_id = (SETTING_HASH.select{|sh| sh[knowlarities_params["dispnumber"].last(10)]}.values.first[:source_id] rescue 2)
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
            sid: knowlarities_params["callid"],
            start_time: Time.zone.parse(knowlarities_params["start_time"]),
            from_number: phone,
            to_number: knowlarities_params["destination"],
            end_time: Time.zone.parse(knowlarities_params["end_time"]),
            recording_url: knowlarities_params["resource_url"],
            duration: knowlarities_params["call_duration"],
            direction: 'incoming',
            phone_number_sid: knowlarities_params["dispnumber"],
            status: (knowlarities_params["call_duration"].to_i > 0  ? 'ANSWER' : 'Missed'),
            call_type: 'Inbound',
            third_party_id: 6
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

     def knowlarities_params
        params.permit(
          :dispnumber,
          :caller_id,
          :start_time,
          :call_date,
          :call_time,
          :end_time,
          :call_duration,
          :agent_call_duration,
          :customer_call_duration,
          :callid,
          :destination,
          :resource_url,
          :recording_url,
          :customer_status
        )
      end

      def create_service_api_log
        ServiceApiLog.create(
          entry_type: 'knowlarities',
          payload: params.except(:controller, :format).to_unsafe_h
        )
      end

    end

  end

end
