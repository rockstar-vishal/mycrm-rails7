module Public
  class OnSiteController < ::PublicApiController
    include MagicFieldsPermittable
    
    before_action :find_broker, only: [:settings, :submit_cp_lead]
    before_action :find_lead, only: [:schedule_client_visit, :client_settings, :lead_details]
    def settings
      render json: {broker_uuid: @broker.uuid, projects: @company.projects.as_api_response(:details)}
    end

    def client_settings
      render json: {message: "Success", data: {lead: @lead.as_api_response(:sv_form_page), projects: @company.projects.as_api_response(:details), units: (@company.magic_fields.find_by(name: "unit_type").items rescue [])}}
    end

    def submit_cp_lead
      render json: {message: "Invalid Data"}, status: 400 and return if @broker.uuid != params[:broker_uuid]
      lead = create_new_lead lead_params.merge(broker_id: @broker.id)
      if lead.save
        render json: {message: "Lead Saved", data: {lead_no: lead.reload.lead_no}}, status: 200 and return
      else
        render json: {message: lead.errors.full_messages.join(', ')}, status: 422 and return
      end
    end

    def lead_details
      render json: {status: true, lead: @lead.as_api_response(:qr_verification).merge(lead_url: "https://#{@company.domain}/leads?search_query=#{params[:lead_no]}")}, status: 200 and return
    end

    def schedule_client_visit
      render json: {message: "Invalid Data"}, status: 400 and return if params[:lead].blank? || params[:lead][:uuid].blank? || @lead.uuid != params[:lead][:uuid]
      
      # Get the parameters
      visit_params = lead_visit_params
      
      if @lead.project.uuid == visit_params[:project_uuid]
        # Update existing lead with magic fields (handled automatically by model)
        @lead.assign_attributes(visit_params)
      else
        origin_lead = @lead
        # Create new lead with the same magic field handling
        @lead = create_new_lead visit_params
        @lead.name = origin_lead.name if @lead.name.blank?
        @lead.email = origin_lead.email if @lead.email.blank?
        @lead.mobile = origin_lead.mobile if @lead.mobile.blank?
        @lead.broker_id = origin_lead.broker_id if @lead.broker_id.blank?
      end
      if @lead.save
        render json: {message: "Visit Scheduled", data: {lead_no: @lead.reload.lead_no}}, status: 200 and return
      else
        render json: {message: "#{@lead.errors.full_messages.join(', ')}"}, status: 422 and return
      end
    end

    private

    def find_broker
      render json: {message: "Invalid CP Code"}, status: 400 and return if params[:cp_code].blank?
      @broker = Broker.find_by_cp_code params[:cp_code]
      @company = @broker.company
    end

    def find_lead
      render json: {message: "Lead No Not Sent"}, status: 400 and return if params[:lead_no].blank?
      @lead = ::Lead.find_by_lead_no params[:lead_no]
      render json: {message: "Lead No Invalid"}, status: 422 and return if @lead.blank?
      @company = @lead.company
    end

    def lead_params
      standard_lead_params(@broker.company)
    end

    def lead_visit_params
      standard_lead_params(@company)
    end

    def create_new_lead input_params
      # Create new lead with magic fields using helper method
      lead = Lead.build_with_magic_fields(@company, input_params)
      lead.status_id = @company.expected_site_visit_id if lead.tentative_visit_planned.present?
      lead.source_id = ::Source.cp_sources.first.id if lead.source_id.blank?
      lead
    end
  end
end