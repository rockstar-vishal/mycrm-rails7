module Public
  class TelecallingController < ::PublicApiController
    include ActionController::HttpAuthentication::Token::ControllerMethods
    before_action :find_company
    TELECALLING_SOURCE_ID = 14

    def create_lead
      project = @company.projects.active.where("lower(replace(name, ' ', '')) = ?", lead_params[:project_name].strip.downcase.gsub(" ", "")).last || @company.default_project
      assigned_to = @company.users.active.find_by_email lead_params[:assigned_to_email] || @company.users.active.superadmins.first
      city = ::City.where("lower(replace(name, ' ', '')) = ?", lead_params[:city_name]&.strip&.downcase&.gsub(" ", ""))&.last
      
      if project.present?
        lead = @company.leads.build(name: lead_params[:name], email: lead_params[:email], mobile: lead_params[:mobile], project_id: project&.id, source_id: TELECALLING_SOURCE_ID)
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
      params.permit(:name, :email, :mobile, :comment, :project_name, :assigned_to_email, :city_name)
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