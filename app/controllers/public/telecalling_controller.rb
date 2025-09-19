module Public
  class TelecallingController < ::PublicApiController
    include ActionController::HttpAuthentication::Token::ControllerMethods
    include MagicFieldsPermittable
    before_action :find_company
    TELECALLING_SOURCE_ID = 14

    def create_lead
      project = @company.projects.active.where("lower(replace(name, ' ', '')) = ?", lead_params[:project_name].strip.downcase.gsub(" ", "")).last || @company.default_project
      assigned_to = @company.users.active.find_by_email lead_params[:assigned_to_email] || @company.users.active.superadmins.first
      city = ::City.where("lower(replace(name, ' ', '')) = ?", lead_params[:city_name]&.strip&.downcase&.gsub(" ", ""))&.last
      
      if project.present?
        # Get the parameters and separate magic fields from regular attributes
        params_data = lead_params.merge(project_id: project&.id, source_id: TELECALLING_SOURCE_ID)
        magic_field_names = magic_field_names_for_company(@company)
        
        # Filter out magic fields from regular attributes
        regular_params = params_data.except(*magic_field_names)
        
        # Create lead with regular attributes
        lead = @company.leads.build(regular_params)
        
        # Handle magic fields by creating MagicAttribute records
        magic_field_names.each do |field_name|
          if params_data[field_name].present?
            magic_field = @company.magic_fields.find_by(name: field_name.to_s)
            if magic_field
              lead.magic_attributes.build(magic_field: magic_field, value: params_data[field_name])
            end
          end
        end
        
        if assigned_to.present?
          lead.user_id = assigned_to.id
        end
        if city.present?
          lead.city_id = city.id
        end
        if lead.save
          render json: {message: "Success", data: {lead_no: lead.reload.lead_no}}, status: 201 and return
        else
          render json: {message: "Failed", errors: lead.errors.full_messages.join(', ')}, status: 422 and return
        end
      end
    end

    private

    def lead_params
      standard_lead_params(@company, [:project_name, :assigned_to_email, :city_name])
    end

    def find_company
      set_company || render_invalid
    end

    def render_invalid
      render json: {message: 'Invalid API Key'}, status: 401 and return
    end

    def set_company
      @company = (::Company.find_by_uuid params[:uuid]) rescue nil
      return true if @company.present?
      return false
    end

  end
end