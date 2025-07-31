module Api
  class MobileCrmController < ::ApiController
    PER_PAGE = 20

    def dashboard
      leads = ::Lead.user_leads(@current_app_user)
      todays_call = leads.todays_calls.count
      backlogs = leads.backlogs_for(@current_app_user.company).count
      expired_lease_count = @current_app_user.company.is_allowed_field?("lease_expiry_date") ? (leads.expired.size) : 0
      expiring_lease_count = @current_app_user.company.is_allowed_field?("lease_expiry_date") ? (leads.expiring.size) : 0
      deactivated_leads_count = leads.unscoped.where(is_deactivated: true).count
      render json: {todays_call: todays_call, backlogs: backlogs, expired_lease_count: expired_lease_count, expiring_lease_count: expiring_lease_count, deactivated_leads_count: deactivated_leads_count}, status: 200 and return
    end

    def settings
      company = @current_app_user.company
      sources = (@current_app_user.is_marketing_manager? ? @current_app_user.accessible_sources : company.sources).reorder(nil).order(:name).select("sources.id, sources.name").as_json
      statuses = company.statuses.latest_first.select("statuses.id, statuses.name").as_json
      dead_status_ids = company.dead_status_ids
      token_status_ids = company.token_status_ids
      bookings_done_ids = [company.booking_done_id]
      site_visit_planned_ids = company.expected_visit_ids.reject(&:blank?).map(&:to_i) | [company.expected_site_visit&.id]
      dead_reasons = company.reasons.active
      sub_sources=company.sub_sources.as_json(only: [:id, :name, :source_id])
      required_fields = company.required_fields.as_json
      cp_sources_ids = company.cp_source_ids
      # channel_partners = company.brokers.reorder(nil).order('name').select("brokers.id, brokers.name").as_json
      channel_partners = company.brokers.reorder(nil).order('name').select("brokers.id, TRIM(brokers.name || ' - ' || COALESCE(brokers.firm_name, '')) AS name").as_json
      countries = Country.select("id, name").as_json
      secondary_source_enabled = company.setting.present? && company.secondary_source_enabled
      is_admin= @current_app_user.is_super?
      allowed_fields=company.allowed_fields.as_json
      disable_edit_lead=@current_app_user.disable_lead_edit
      disable_new_lead=@current_app_user.disable_create_lead
      is_sv_project_enabled=company.setting.present? && company.is_sv_project_enabled
      is_source_wise_sub_source_enabled=company.setting.present? && company.enable_source_wise_sub_source
      render json: {sources: sources, statuses: statuses, dead_status_ids: dead_status_ids, bookings_done_ids: bookings_done_ids, dead_reasons: dead_reasons, site_visit_planned_ids: site_visit_planned_ids, token_status_ids: token_status_ids,  sub_source: sub_sources, required_fields: required_fields, cp_sources_ids: cp_sources_ids, channel_partners: channel_partners, countries: countries, secondary_source_enabled: secondary_source_enabled, is_admin: is_admin, allowed_fields: allowed_fields, disable_edit_lead: disable_edit_lead, disable_new_lead: disable_new_lead, is_telecaller_user: @current_app_user.is_telecaller?, is_sv_project_enabled: is_sv_project_enabled, is_source_wise_sub_source_enabled: is_source_wise_sub_source_enabled}, status: 200 and return
    end

    def user_incentive_detail
      render json: @current_app_user.user_detail.other_data, status: 200 and return
    end

    def status_wise_stage
      stages = @current_app_user.company.status_wise_stage_data
      render json: {stages: stages}, status: 200 and return
    end

    def suggest_users
      render json: {status: false, message: "Please enter search string"}, status: 400 and return if (params[:input_str].blank? || params[:input_str].length < 3)
      if @current_app_user.company.can_assign_all_users || @current_app_user.assign_all_users_permission
        users = @current_app_user.company.users.active
      else
        users = @current_app_user.manageables.active
      end
      users = users.where("users.name ILIKE ?", "#{params[:input_str].downcase}%").select("users.id, users.name").as_json
      render json: {users: users}, status: 200 and return
    end

    def additional_settings
      tile_img=(@current_app_user.company.logo.url rescue "")
      enable_complete_lead_update=@current_app_user.company.setting.present? && @current_app_user.company.enable_mcrm_complete_lead_update
      render json: {tile_img: tile_img, enable_complete_lead_update: enable_complete_lead_update}, status: 200 and return
    end

    def suggest_managers
      render json: {status: false, message: "Please enter search string"}, status: 400 and return if (params[:input_str].blank? || params[:input_str].length < 3)
      managers = @current_app_user.manageables.active.managers.where("users.name ILIKE ?", "#{params[:input_str].downcase}%").select("users.id, users.name").as_json
      render json: {managers: managers}, status: 200 and return
    end

    def suggest_projects
      render json: {status: false, message: "Please enter search string"}, status: 400 and return if (params[:input_str].blank? || params[:input_str].length < 3)
      projects = @current_app_user.company.projects.where("projects.name ILIKE ?", "#{params[:input_str].downcase}%").select("projects.id, projects.name").as_json
      render json: {projects: projects}, status: 200 and return
    end

    def call_logs
      start_date = params[:start_date].present? ? Time.zone.parse(params[:start_date]).beginning_of_day : (Time.zone.now - 7.days).beginning_of_day
      end_date = params[:end_date].present? ? Time.zone.parse(params[:end_date]).end_of_day : Time.zone.now.end_of_day

      base_scoped_data = @current_app_user.company.call_logs.where("leads_call_logs.user_id IN (?) AND leads_call_logs.created_at BETWEEN ? AND ?", @current_app_user.manageables.ids, start_date, end_date)
      base_scoped_data = base_scoped_data.advance_search(bs: params[:bs]) if params[:bs].present?
      if params["status"].present? && ["incoming", "outgoing", "missed"].include?(params[:status])
        base_scoped_data = base_scoped_data.send(params[:status])
      end
      total_count = base_scoped_data.count
      base_scoped_data = base_scoped_data.paginate(page: params[:page], per_page: PER_PAGE)
      render json: {data: base_scoped_data.as_api_response(:call_log_details), total_count: total_count, per_page: PER_PAGE}, status: 200 and return
    end
  end
end