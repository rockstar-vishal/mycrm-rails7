class ProjectsController < ApplicationController
  before_action :set_projects
  before_action :set_project, only: [:show, :edit, :update, :destroy]

  respond_to :html
  PER_PAGE = 20

  def index
    @projects = @projects
    if current_user.company.setting.present? && current_user.company.setting.enabled_project_wise_access && current_user.accessible_projects.present?
      @projects = @projects.where(id: current_user.accessible_projects.ids)
    end
    if params[:search_string].present?
      @projects = @projects.basic_search(params[:search_string])
    end
    @projects = @projects.sorted.paginate(:page => params[:page], :per_page => PER_PAGE)
  end

  def show
    @project = @projects.find_by(uuid: params[:uuid])
    respond_to do |format|
      format.js
    end
  end

  def new
    @project = @projects.new
    render_modal 'new'
  end

  def edit
    render_modal 'edit'
  end

  def create
    @project = @projects.new(project_params)
    if @project.save
      flash[:notice] = "Project created successfully"
      xhr_redirect_to redirect_to: projects_path and return
    else
      render_modal 'new'
    end
  end

  def update
    if @project.update_attributes(project_params)
      flash[:notice] = "Project updated successfully"
      xhr_redirect_to redirect_to: projects_path
    else
      render_modal 'edit'
    end
  end

  def destroy
    if @project.destroy
      flash[:success] = "Project deleted successfully"
    else
      flash[:notice] = "Cannot delete this project - #{@project.errors.full_messages.join(', ')}"
    end
    redirect_to :back and return
  end

  private
    def set_project
      @project = @projects.find_by_uuid params[:uuid]
    end

    def set_projects
      @projects = current_user.company.projects
    end

    def project_params
      params.require(:project).permit(
        :name,
        :company_id,
        :city_id,
        :address,
        :active,
        :housing_token,
        :mb_token,
        :nine_token,
        :smartping_project_id,
        :is_default,
        :contact,
        :country_id,
        :brochure_link,
        :location,
        :project_brochure,
        :banner_image,
        :description,
        :sv_form_budget_options,
        property_codes: [],
        fb_form_nos: [],
        dyn_assign_user_ids: [],
        dyn_assign_closing_executive_ids: [],
        projects_fb_forms_attributes: [
          :id,
          :title,
          :form_no,
          :enquiry_sub_source_id,
          :_destroy
        ],
        fb_ads_ids_attributes: [
          :id,
          :number,
          :_destroy
        ],
        round_robin_settings_attributes: [
          :id,
          :_destroy,
          :user_id,
          :source_id,
          :sub_source_id
        ]
      )
    end
end
