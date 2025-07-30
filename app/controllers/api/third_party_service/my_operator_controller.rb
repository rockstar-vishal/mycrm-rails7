module Api

  module ThirdPartyService

    class MyOperatorController < PublicApiController

      before_action :find_company

      PROJECT_HASH = {
        "7304633333" => {project_id: 4776},
        "8448449233" => {project_id: 4776},
        "7303203333" => {project_id: 4777},
        "9582370390" => {project_id: 4777},
        "8448449833" => {project_id: 4778},
        "8929338435" => {project_id: 4778},
        "8377845845" => {project_id: 4841}
      }

      SETTING_HASH = {
        "8448449233" => {source_id: 533},
        "7304633333" => {source_id: 532},
        "9582370390" => {source_id: 535},
        "7303203333" => {source_id: 534},
        "8929338435" => {source_id: 537}
      }


      def hangup
        phone = call_params["mobile_number"]&.last(10)
        executive_phone = call_params["executive_info"]&.last(10)
        user = @company.users.find_by(mobile: executive_phone) || @company.users.active.superadmins.first
        project_id = (PROJECT_HASH.select{|sh| sh[call_params["ivr_no"].last(10)]}.values.first[:project_id] rescue @company.default_project&.id)
        user_id = user&.id
        @leads = @company.leads.active_for(@company).where(project_id: project_id).where("mobile LIKE ?", "%#{phone}") if phone.present?
        if @leads.present?
          @lead = @leads.last
        else
          selected_source_id = (SETTING_HASH.select{|sh| sh[call_params["ivr_no"].last(10)]}.values.first[:source_id] rescue 2)
          @lead = @company.leads.new(
              mobile: phone,
              project_id: project_id,
              status_id: @company.new_status_id,
              source_id: selected_source_id,
            )
        end
        @lead.user_id = @lead.user_id || user_id
        unless @lead.save
          render json: {status: "Failure", message: @lead.errors.full_messages.join(', ')}, status: 422 and return
        end
        call_log = @lead.call_logs.build(
          user_id: @lead.user_id,
          caller: 'Lead',
          sid: call_params["sid"],
          start_time: (Time.at(call_params[:start_time].to_i) rescue Time.zone.now),
          from_number: @lead.mobile,
          to_number: call_params["executive_info"],
          end_time: (Time.at(call_params[:end_time].to_i) rescue Time.zone.now),
          recording_url: call_params[:recording_url],
          duration: call_params["duration"],
          direction: call_params[:direction] || 'incoming',
          status: call_params["status"],
          third_party_id: 'myoperator'
        )
        if call_log.save
          render json: {status: "Success"}, status: 200 and return
        else
          render json: {status: "Failure", message: call_log.errors.full_messages.join(', ')}, status: 422 and return
        end
      end

      private

      def find_company
        @company = Company.find_by(uuid: params[:uuid]) rescue nil
        if @company.blank?
          render json: {status: false, message: "Invalid Request"}, status: 422 and return
        end
      end

      def call_params
        params.permit(
          :sid,
          :executive_info,
          :ivr_no,
          :mobile_number,
          :start_time,
          :end_time,
          :recording_url,
          :duration,
          :status,
          :direction
        )
      end

    end

  end

end
