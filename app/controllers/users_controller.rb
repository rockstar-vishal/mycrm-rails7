class UsersController < ApplicationController
  before_action :set_users, except: [:edit_profile, :update_profile, :edit_user_config]
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :build_user_detail_attributes, only: :edit

  respond_to :html
  PER_PAGE = 50

  def index
    if params[:search_query].present?
      @users = @users.basic_search(params[:search_query])
    end
    if params[:is_advanced_search].present? && params[:search_query].blank?
      @users = @users.advance_search(search_params)
    end
    respond_to do |format|
      format.html do
        @users = @users.paginate(:page => params[:page], :per_page => PER_PAGE)
      end
      format.csv do
        send_data @users.order(created_at: :asc).to_csv({}, current_user, request.remote_ip, @users.count), filename: "users_#{Date.today.to_s}.csv"
      end
    end
  end

  def show
    render_modal('show', {:class=>'right'})
  end

  def new
    @user = @users.new
    build_user_detail_attributes
  end

  def edit
  end

  def create
    @user = @users.new(user_params)
    if @user.save
      flash[:notice] = "User created successfully"
      redirect_to users_path and return
    else
      render 'new'
    end
  end

  def update
    if @user.update(user_params)
      flash[:notice] = "User Updated Successfully"
      redirect_to users_path
    else
      render 'edit'
    end
  end

  def edit_profile
    @user = current_user
  end

   def update_profile
    @user = current_user
    if params[:user][:password].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end
    if @user.update(user_profile_params)
      flash[:notice] = "Profile Updated Successfully"
      redirect_to users_path
    else
      render 'edit'
    end
  end

  def edit_user_config
    @users = current_user.manageables
    render_modal 'edit_user_config'
  end
  
  def profile_image
    user = User.find(params[:id])
    if user.profile_image_data.present?
      # Custom decoding approach
      decoded_data = decode_image_data(user.profile_image_data)
      send_data decoded_data, 
                type: user.profile_image_content_type, 
                disposition: 'inline',
                filename: user.profile_image_filename
    else
      head :not_found
    end
  end
  
  
  def decode_image_data(encoded_data)
    # Custom decoding approach matching the encoding method
    decoded = encoded_data.chars.map { |c| (c.ord - 13).chr }.join
    Base64.strict_decode64(decoded)
  end

  def enable_round_robin
    current_user.manageables.each do |user|
      if params[:users_list].present?
        params[:users_list].include?(user.id.to_s) ? user.update(:round_robin_enabled => true) : user.update(:round_robin_enabled => false)
      end
    end
    company = current_user.company
    if company.update(:round_robin_enabled => true)
      flash[:notice] = "Round Robin Assignment enabled successfully"
    else
      flash[:alert] = "Cannot enable Round Robin Assignment - #{company.errors.full_messages.join(', ')}"
    end
    
    respond_to do |format|
      format.js do
        render js: "window.location.href = '#{configurations_path}';"
      end
      format.html do
        redirect_to configurations_path
      end
    end
  end

  def disable_round_robin
    company = current_user.company
    current_user.manageables.round_robin_users.each do |user|
      if params[:users_list].present?
        params[:users_list].include?(user.id.to_s) ? user.update(:round_robin_enabled => true) : user.update(:round_robin_enabled => false)
      else
        flash[:alert] = "Atleast one user should have round robin enabled"
        respond_to do |format|
          format.js do
            xhr_redirect_to redirect_to: request.referer
          end
          format.html do
            redirect_to request.referer
          end
        end
        return
      end
    end

    users = current_user.manageables.round_robin_users
    company.projects.each do |project|
      if project.dyn_assign_user_ids.present?
        project.dyn_assign_user_ids = project.dyn_assign_user_ids & users.pluck(:id).map(&:to_s)
        project.save
      end
    end

    if users.count > 1 || (users.count == 1 && company.update(:round_robin_enabled => false))
      flash[:notice]  = "Round Robin Assignment disabled successfully"
    else
      flash[:alert] = "Cannot disable this functionality - #{company.errors.full_messages.join(',')}"
    end
    
    respond_to do |format|
      format.js do
        xhr_redirect_to redirect_to: request.referer
      end
      format.html do
        redirect_to request.referer
      end
    end
  end

  def destroy
    if @user.destroy
      flash[:success] = "User deleted successfully"
    else
      flash[:danger] = "Cannot delete this User - #{@user.errors.full_messages.join(', ')}"
    end
    redirect_to users_path and return
  end

  def build_user_detail_attributes
    @user.build_user_detail if @user.user_detail.blank?
  end

  private
    def set_user
      @user = @users.find_by_uuid params[:uuid]
    end

    def set_users
      if current_user.is_sysad?
        @users = ::User.superadmins
      else
        if current_user.is_super?
          @users = current_user.company.users
        else
          @users = current_user.manageables
        end
      end
    end
    
    def search_params
      params.permit(
        :name,
        :email,
        :mobile,
        :created_at_from,
        :created_at_upto,
        :updated_from,
        :updated_upto,
        role_ids: []
      )
    end

    def users_params
      params.permit(:search_query, :page, :is_advanced_search, :name, :email, :mobile, :created_at_from, :created_at_upto, :updated_from, :updated_upto, role_ids: [])
    end
    helper_method :users_params

    def user_params
      permitted = params.require(:user).permit(
        :name,
        :mobile,
        :email,
        :role_id,
        :city_id,
        :state,
        :country,
        :active,
        :role_id,
        :click_to_call_enabled,
        :exotel_sid_id,
        :mcube_sid_id,
        :round_robin_enabled,
        :can_import,
        :can_export,
        :can_delete_lead,
        :disable_create_lead,
        :disable_lead_edit,
        :password,
        :password_confirmation,
        :caller_desk_project_id,
        :agent_id,
        :ivr_id,
        :is_meeting_executive,
        :is_calling_executive,
        :cloud_telephony_sid_id,
        :can_access_project,
        :assign_all_users_permission,
        :manager_mappings_attributes=>[:id, :_destroy, :manager_id],
        :round_robin_settings_attributes => [:id, :_destroy, :source_id, :sub_source_id, :project_id],
        :users_projects_attributes => [:id, :_destroy, :project_id, :user_id],
        :users_sources_attributes => [:id, :_destroy, :source_id, :user_id],
        :user_detail_attributes => [:id, :paid_incentive, :pending_incentive, :earned_incentive]
      )
      permitted = permitted.except(:password, :password_confirmation) if permitted[:password].blank?
      permitted.merge!(company_id: params[:user][:company_id]) if current_user.is_sysad?
      permitted
    end

    def user_profile_params
      params.require(:user).permit(
        :name,
        :mobile,
        :email,
        :password,
        :password_confirmation,
        :profile_image_upload
      )
    end
end
