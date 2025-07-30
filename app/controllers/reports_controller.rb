class ReportsController < ApplicationController

  before_action :set_company_props
  before_action :set_start_end_date
  before_action :set_base_leads, except: [:campaigns, :campaigns_report, :campaign_detail, :activity, :activity_details, :visits, :source_wise_visits, :trends, :site_visit_planned, :customized_status_dashboard, :scheduled_site_visits, :scheduled_site_visits_detail, :presale_visits, :gre_source_report]
  helper_method :ld_path, :bl_path, :dld_path, :ad_path, :comment_edit_text, :status_edit_html, :vd_path, :user_edit_html, :source_edit_html

  def source
    data = @leads.group("source_id, status_id").select("COUNT(*), source_id, status_id, json_agg(id) as lead_ids")
    @statuses = @statuses.where(:id=>data.map(&:status_id).uniq)
    @sources = @sources.where(:id=>data.map(&:source_id).uniq)
    @data = data.as_json(except: [:id])
    respond_to do |format|
      format.html
      format.csv do
        send_data @leads.source_report_to_csv({}, current_user), filename: "source_wise_report_#{Date.today.to_s}.csv"
      end
    end
  end

  def sub_source
    data = @leads.where.not(enquiry_sub_source_id: nil).group("enquiry_sub_source_id, status_id").select("COUNT(*), enquiry_sub_source_id as sub_source_id, status_id, json_agg(id) as lead_ids")
    @statuses = @statuses.where(:id=>data.map(&:status_id).uniq)
    @sub_sources = @sub_sources.where(:id=>data.map(&:sub_source_id).uniq)
    @data = data.as_json(except: [:id])
  end

  def trends
    render json: {message: "You are not allowed to access this"}, status: 403 unless (current_user.is_super? || current_user.is_sl_admin?)
    dates_range = (@start_date.to_date..@end_date.to_date).to_a
    @leads = @leads.filter_leads_for_reports(params, current_user)
    @lead_gen = @leads.where(:created_at=>@start_date..@end_date).group("date(created_at)").select("COUNT(*), date(created_at) as created_date").as_json(except: [:id])
    dates_range.map{|k| @lead_gen.select{|a| a['created_date'] == k}.present? ? true : @lead_gen << {"created_date"=>k, "count"=>0}}
    @conversions = @leads.where(:conversion_date=>@start_date.to_date..@end_date.to_date).booked_for(current_user.company).group("conversion_date").select("conversion_date, COUNT(*)").as_json(except: [:id])
    dates_range.map{|k| @conversions.select{|a| a['conversion_date'] == k}.present? ? true : @conversions << {"conversion_date"=>k, "count"=>0}}
    @visits = @leads.joins{visits}.where("leads_visits.date BETWEEN ? AND ?", @start_date.to_date, @end_date.to_date).group("leads_visits.date").select("COUNT(*), leads_visits.date as visit_date").as_json(except: [:id])
    dates_range.map{|k| @visits.select{|a| a['visit_date'] == k}.present? ? true : @visits << {"visit_date"=>k, "count"=>0}}
  end

  def projects
    data = @leads.group("project_id, status_id").select("COUNT(*), project_id, status_id, json_agg(id) as lead_ids")
    uniq_projects = @leads.map{|k| k[:project_id]}.uniq
    uniq_statuses = @leads.map{|k| k[:status_id]}.uniq
    @projects = @projects.where(:id=>uniq_projects)
    @statuses = @statuses.where(:id=>uniq_statuses)
    @data = data.as_json(except: [:id])
    respond_to do |format|
      format.html
      format.csv do
        send_data @leads.project_report_to_csv({}, current_user), filename: "project_wise_report_#{Date.today.to_s}.csv"
      end
    end
  end

  def call_report
    @data = Leads::CallLog.includes(:user).where("leads_call_logs.user_id IN (?) AND leads_call_logs.created_at BETWEEN ? AND ?", current_user.manageables.ids, @start_date, @end_date)
    if params[:is_advanced_search].present?
      @data = @data.advance_search(call_log_report_params)
    end
    @users = current_user.manageables.where(id: @data.map(&:user_id))
    respond_to do |format|
      format.html
      format.csv do
        send_data @data.calls_report_to_csv({}, current_user, @start_date, @end_date), filename: "calls_wise_report_#{Date.today.to_s}.csv"
      end
    end
  end

  def source_wise_visits
    if current_user.company.enable_advance_visits
      data = Lead.leads_visits_combinations(visit_params.merge(is_visit_executed: true, start_date: @start_date, end_time: @end_date), current_user.company_id, current_user, is_source_wise: true)
    else
      data = Lead.leads_visits_combinations(visit_params.merge(start_date: @start_date, end_time: @end_date), current_user.company_id, current_user, is_source_wise: true)
    end
    @statuses = @statuses.where(:id=>data.map(&:status_id).uniq)
    @sources = @sources.where(:id=>data.map(&:source_id).uniq)
    @source_ids=@sources.ids
    @manageable_ids = current_user.manageables.ids
    @data = data.as_json

    respond_to do |format|
      format.html
      format.csv do
        send_data Lead.source_visits_to_csv({}, data, current_user), filename: "source_visits_report_#{Date.today.to_s}.csv"
      end
    end
  end

  def visits
    if current_user.company.enable_advance_visits
      data = Lead.leads_visits_combinations(visit_params.merge(is_visit_executed: true, start_date: @start_date, end_time: @end_date), current_user.company_id, current_user)
    else
      data = Lead.leads_visits_combinations(visit_params.merge(start_date: @start_date, end_time: @end_date), current_user.company_id, current_user)
    end

    @statuses = @statuses.where(:id=>data.map(&:status_id).uniq)
    @manageable_ids = current_user.manageables.ids
    @data = data.as_json

    respond_to do |format|
      format.html
      format.csv do
        send_data Lead.visits_to_csv({}, data, current_user), filename: "visits_report_#{Date.today.to_s}.csv"
      end
    end
  end

  def presale_visits
    @leads = @leads.joins{visits}.where("leads_visits.date BETWEEN ? AND ?", @start_date.to_date, @end_date.to_date)
    @presale_users = current_user.manageables.where(:id=>@leads.map(&:presale_user_id))
    @statuses = @statuses.where(:id=>@leads.map(&:status_id))
  end

  def campaigns
    @leads = @leads.includes(:visits).where(:user_id=>current_user.manageable_ids)
    if params[:sub_source_ids].present?
      @leads = @leads.where(enquiry_sub_source_id: params[:sub_source_ids])
    end
    @campaigns = current_user.company.campaigns
    respond_to do |format|
      format.html
      format.csv do
        send_data @leads.campaign_report_to_csv({}, current_user), filename: "campaign_report_#{Date.today.to_s}.csv"
      end
    end
  end

  def campaigns_report
    @projects = current_user.company.projects
    start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : (Date.today - 2.months)

    @campaigns = if params[:advance_search].present?
                  filtered_campaigns(current_user.company.campaigns.includes(:source, :spends))
                 else
                  current_user.company.campaigns.includes(:source, :spends)
                              .where('start_date >= ?', start_date)
                 end
    @campaigns.each do |campaign|
      campaign.calculate_metrics(@leads)
    end
  end

  def campaign_detail
    @campaign = current_user.company.campaigns.find_by(uuid: params[:campaign_uuid])
    @leads = @leads.where(:user_id=>current_user.manageable_ids)
    @campaign_leads = @leads.where(created_at: @campaign.start_date.beginning_of_day..@campaign.end_date.end_of_day, source_id: @campaign.source_id)
    @campaign_visited_leads = @campaign_leads.joins{visits}.uniq
    @campaign_date_range = @campaign_leads.order(created_at: :desc).pluck(:created_at).map(&:to_date).uniq
  end

  def backlog
    company = current_user.company
    @leads = @leads.backlogs_for(company)
    @leads = @leads.where(user_id: current_user.manageable_ids)
    data = @leads.group("user_id, status_id").select("COUNT(*), user_id, status_id, json_agg(leads.id) as lead_ids")
    @statuses = @statuses.where(:id=>data.map(&:status_id).uniq)
    @users = current_user.manageables.where(:id=>data.map(&:user_id).uniq)
    @data = data.as_json
    respond_to do |format|
      format.html
      format.csv do
        send_data @leads.backlog_report_to_csv({}, current_user), filename: "back_logs_report_#{Date.today.to_s}.csv"
      end
    end
  end

  def closing_executive_backlog
    company = current_user.company
    @leads = @leads.backlogs_for(company)
    data = @leads.where.not(closing_executive: nil).group("closing_executive, status_id").select("COUNT(*), closing_executive as user_id, status_id, json_agg(leads.id) as lead_ids")
    @statuses = @statuses.where(:id=>data.map(&:status_id).uniq)
    @users = current_user.manageables.where(:id=>data.map(&:user_id).uniq)
    @data = data.as_json
    respond_to do |format|
      format.html
      format.csv do
        send_data @leads.closing_executive_backlog_report_to_csv({}, current_user), filename: "closing_executive_backlog_report_#{Date.today.to_s}.csv"
      end
    end
  end

  def source_wise_inactive
    @data = @leads.where(:status_id=>current_user.company.dead_status_ids, user_id: current_user.manageables.ids)
    @reasons = current_user.company.reasons.where(:id=>@data.map(&:dead_reason_id).uniq)
    @sources=@sources.where(id: @data.map(&:source_id).uniq)
    respond_to do |format|
      format.html
      format.csv do
        send_data @leads.source_inactive_report_to_csv({}, current_user), filename: "source_inactive_lead_report_#{Date.today.to_s}.csv"
      end
    end
  end

  def dead
    @data = @leads.where(:status_id=>current_user.company.dead_status_ids)
    @reasons = current_user.company.reasons.where(:id=>@data.map(&:dead_reason_id).uniq)
    @users = current_user.manageables.where(:id=>@data.map(&:user_id).uniq)
    respond_to do |format|
      format.html
      format.csv do
        send_data @leads.dead_report_to_csv({}, current_user), filename: "dead_lead_report_#{Date.today.to_s}.csv"
      end
    end
  end

  def leads
    data = @leads.group("user_id, status_id").select("COUNT(*), user_id, status_id, json_agg(leads.id) as lead_ids")
    @statuses = @statuses.where(:id=>data.map(&:status_id).uniq)
    @users = current_user.manageables.where(:id=>data.map(&:user_id).uniq)
    @data = data.as_json
    respond_to do |format|
      format.html
      format.csv do
        send_data @leads.report_to_csv({}, current_user), filename: "lead_user_wise_report_#{Date.today.to_s}.csv"
      end
    end
  end

  def scheduled_site_visits
    @start_date = params[:start].present? ? Time.zone.parse(params[:start]).beginning_of_day : (Time.zone.now).beginning_of_day
    @end_date = params[:end].present? ? Time.zone.parse(params[:end]).end_of_day : (Time.zone.now + start_offset.day).end_of_day
    @leads = @leads.site_visit_planned_leads(current_user).where("leads.tentative_visit_planned BETWEEN ? AND ?", @start_date.to_date, @end_date.to_date)
    render json: @leads.as_api_response(:event)
  end

  def scheduled_site_visits_detail
    @default_tab = 'leads-detail'
    @lead = @leads.find_by(id: params[:lead_id])
    @company = current_user.company
    render_modal('leads/show', {:class=>'right'})
  end

  def user_call_reponse_report
    data = current_user.company.call_attempts.where.not(response_time: nil).where(user_id: current_user.manageable_ids)
    data = data.where(created_at: @start_date..@end_date)
    if params[:is_advanced_search].present?
      data = data.advance_search(user_call_reponse_search)
    end
    data = data.group("call_attempts.user_id").select("COUNT(*) as count, call_attempts.user_id as user_id, sum(response_time) as response_time, json_agg(call_attempts.id) as call_attempts_ids, json_agg(call_attempts.lead_id) as lead_ids")
    @users = current_user.manageables.where(:id=>data.map(&:user_id).uniq)
    @data = data.as_json
  end

  def site_visit_planned_tracker
    @data = @leads.site_visit_scheduled
    @users = current_user.manageables.where(:id=>@data.map(&:user_id).uniq)
    respond_to do |format|
      format.html
      format.csv do
        send_data @leads.svp_tracker_to_csv({}, current_user), filename: "svp_tracker_#{Date.today.to_s}.csv"
      end
    end
  end

  def customized_status_dashboard
    start_offset = 60
    @statuses= current_user.company.statuses.where(id: current_user.company.customize_report_status_ids.reject(&:blank?).map(&:to_i))
    @start_date = params[:start_date].present? ? Time.zone.parse(params[:start_date]).beginning_of_day : (Time.zone.now - start_offset.day).beginning_of_day 
    @end_date = params[:end_date].present? ? Time.zone.parse(params[:end_date]).end_of_day : (Time.zone.now).end_of_day
    @leads = @leads.where("leads.status_id IN (?) AND leads.created_at BETWEEN ? AND ?",@statuses.ids, @start_date.to_date, @end_date.to_date)
    if params[:is_advanced_search].present?
      @leads=@leads.advance_search(status_dashboard_params, current_user)
    end
    respond_to do |format|
      format.html do
        @leads = @leads.includes{visits}.paginate(:page => params[:page], :per_page => 50)
      end
    end
  end

  def site_visit_planned
    if current_user.company.setting.present? && current_user.company.set_svp_default_7_days
      start_offset= 7
    else
      start_offset = 60
    end
    @start_date = params[:start_date].present? ? Time.zone.parse(params[:start_date]).beginning_of_day : (Time.zone.now).beginning_of_day
    @end_date = params[:end_date].present? ? Time.zone.parse(params[:end_date]).end_of_day : (Time.zone.now + start_offset.day).end_of_day
    @leads = @leads.site_visit_planned_leads(current_user).where("leads.tentative_visit_planned BETWEEN ? AND ?", @start_date.to_date, @end_date.to_date)
    if params[:project_ids].present? || params[:manager_id].present? || params[:manager_ids].present? || params[:visit_status_ids].present?
      @leads=@leads.filter_leads_for_reports(params, current_user)
    end
    if params["visited"].present? && params["visited"] == "true"
      @leads = @leads.joins{visits}
    end
    @leads_count = @leads.size
    if params["key"].present? && params["sort"].present?
      @leads = @leads.order("#{params['key']} #{params['sort']} NULLS FIRST")
    else
      @leads = @leads.order("leads.tentative_visit_planned asc NULLS FIRST, leads.created_at DESC")
    end
    if params[:calender_view].present?
      @leads = @leads
      render 'site_visit_planned_calender_view'
    else
      respond_to do |format|
        format.html do
          @leads = @leads.includes{visits}.order("leads.tentative_visit_planned ASC").paginate(:page => params[:page], :per_page => 50)
        end
        format.csv do
          if @leads_count <= 4000
            send_data @leads.to_csv({}, current_user), filename: "Site_visit_planned_#{Date.today.to_s}.csv"
          else
            render json: {message: "Export of more than 4000 leads is not allowed in one single attempt. Please contact management for more details"}, status: 403
          end
        end
      end
    end
  end

  def activity
    activities = current_user.company.associated_audits.where(:created_at=>@start_date..@end_date)
    unless current_user.is_super?
      activities = activities.where(:user_id=>current_user.manageable_ids, :user_type=>"User")
    end
    lead_ids = activities.pluck(:auditable_id)
    leads = current_user.manageable_leads.where(:id=>lead_ids.uniq)
    leads = leads.filter_leads_for_reports(activity_search_params, current_user)
    activities = activities.where(:auditable_id=>leads.ids.uniq)
    @unique_activities = activities.select("DISTINCT ON (audits.auditable_id) audits.* ")
    @status_edits = activities.where("audits.audited_changes ->> 'status_id' != ''").group("user_id").select("user_id, json_agg(audited_changes) as change_list")
    @user_edits = activities.where("audits.audited_changes ->> 'user_id' != ''").group("user_id").select("user_id, json_agg(audited_changes) as change_list")
    @comment_edits = activities.where("audits.audited_changes ->> 'comment' != ''").group("user_id").select("user_id, json_agg(audited_changes) as change_list")
    @users = current_user.manageables.where(:id=>(@status_edits.map(&:user_id).uniq | @comment_edits.map(&:user_id).uniq))
    @status_edits = @status_edits.as_json
    @comment_edits = @comment_edits.as_json
    @user_edits=@user_edits.as_json
    respond_to do |format|
      format.html
      format.csv do
        send_data @leads.activity_to_csv({}, current_user, @start_date, @end_date), filename: "activities_report_#{Date.today.to_s}.csv"
      end
    end
  end

  def activity_details
    @user = current_user.manageables.find(params[:user_id])
    @activities = ::CustomAudit.joins{lead}.where(associated_id: current_user.company_id,auditable_type: "Lead").where(:created_at=>@start_date..@end_date, :user_id=>@user.id, :user_type=>"User")
    if params[:source_id].present?
      @activities = @activities.where("leads.source_id IN (?)", params[:source_id])
    end
    if params[:lead_statuses].present?
      @activities = @activities.where("leads.status_id IN (?)", params[:lead_statuses])
    end
    if params[:project_ids].present?
      @activities = @activities.where("leads.project_id IN (?)", params[:project_ids])
    end
    if params[:distinct_leads].present?
      @activities=@activities.select("DISTINCT ON (audits.auditable_id) audits.* ").order(auditable_id: :asc)
    else
      if @current_user.company.setting.present? && @current_user.company.enable_activity_report_source_logs
        @activities = @activities.where("audits.audited_changes ->> 'status_id' != '' OR audits.audited_changes ->> 'comment' != '' OR audits.audited_changes ->> 'source_id' != ''").order(auditable_id: :asc)
      else
        @activities = @activities.where("audits.audited_changes ->> 'status_id' != '' OR audits.audited_changes ->> 'comment' != ''").order(auditable_id: :asc)
      end
    end
    @statuses_list = @current_user.company.statuses.select("statuses.id, statuses.name").as_json
    @sources_list = @current_user.company.sources.select("sources.id, sources.name").as_json
    @users_list = @current_user.company.users.select("users.id, users.name").as_json
    respond_to do |format|
      format.html
      format.csv do
        send_data @leads.activity_details_to_csv(@activities, current_user, view_context), filename: "activity_details_report_#{Date.today}.csv"
      end
    end
  end

  def closing_executives
    data = @leads.where.not(closing_executive: nil).group("closing_executive, status_id").select("COUNT(*), closing_executive, status_id, json_agg(leads.id) as lead_ids")
    @statuses = current_user.company.statuses.where(:id=>data.map(&:status_id).uniq)
    @users = current_user.manageables.where(:id=>data.map(&:closing_executive).uniq)
    @data = data.as_json
    puts @data
    respond_to do |format|
      format.html
      format.csv do
        send_data @leads.closing_executive_to_csv({}, current_user), filename: "lead_closinguser_wise_report_#{Date.today.to_s}.csv"
      end
    end
  end

  def gre_source_report
    @leads = @leads.where(:created_at=>@start_date..@end_date)
    data = @leads.joins{visits}.group("leads.source_id, leads.status_id").select("COUNT(*), leads.source_id, leads.status_id, json_agg(leads.id) as lead_ids")
    @statuses = @statuses.where(:id=>data.map(&:status_id).uniq)
    @sources = @sources.where(:id=>data.map(&:source_id).uniq)
    @data = data.as_json(except: [:id])
    respond_to do |format|
      format.html
      format.csv do
        send_data @leads.gre_source_report_to_csv({}, current_user), filename: "source_report_#{Date.today.to_s}.csv"
      end
    end
  end

  def source_report
    data = @leads.group("source_id, status_id").select("COUNT(*), source_id, status_id, json_agg(id) as lead_ids")
    @statuses = @statuses.where(:id=>data.map(&:status_id).uniq)
    @sources = @sources.where(:id=>data.map(&:source_id).uniq)
    @campaigns = current_user.company.campaigns
    @site_visit_done_id = current_user.company.site_visit_done_id
    @booking_done_id = current_user.company.booking_done_id
    @dead_status_ids = current_user.company.dead_status_ids
    @leads = @leads.where(id: data.map(&:lead_ids).flatten).where.not(status_id: @dead_status_ids).joins("LEFT JOIN audits ON audits.auditable_id = leads.id AND audits.auditable_type = 'Lead'").joins("LEFT JOIN leads_visits ON leads_visits.lead_id = leads.id").where("audits.action = 'update' AND audits.audited_changes ->> 'status_id' != ''").group("leads.id, leads.created_at").select("leads.id, leads.created_at, MIN(audits.created_at) AS first_status_edit_audit_date, MIN(leads_visits.date) AS first_visit_date").as_json
    @data = data.as_json(except: [:id])
  end

  def channel_partner
    data = @leads.where.not(broker_id: nil).where("source_id IN (?)", current_user.company.cp_sources&.ids).group("broker_id, status_id").select("COUNT(*), broker_id, status_id, json_agg(leads.id) as lead_ids")
    @statuses = @statuses.where(:id=>data.map(&:status_id).uniq)
    if params[:firm_names].present?
      # broker_ids_with_firm_names = current_user.company.brokers.where(firm_name: params[:firm_names]).pluck(:id)
      broker_ids_with_firm_names = current_user.company.brokers.where("LOWER(firm_name) IN (?)", params[:firm_names]).pluck(:id)
      data = data.where(broker_id: broker_ids_with_firm_names)
    end
    if params[:broker_name].present?
      data = data.joins(:broker).where("LOWER(brokers.name) = ?", params[:broker_name].downcase)
    end
    @brokers = current_user.company.brokers.where(:id=>data.map(&:broker_id).uniq)
    @data = data.as_json(except: [:id])
    respond_to do |format|
      format.html
      format.csv do
        send_data data.cp_report_to_csv({}, current_user), filename: "cp_wise_report_#{Date.today.to_s}.csv"
      end
    end
  end

  def site_visit_userwise
    @data = @leads.joins{visits}.where("leads_visits.date BETWEEN ? AND ?", @start_date.to_date, @end_date.to_date).group("leads_visits.user_id").select("COUNT(*),leads_visits.user_id, json_agg(leads_visits.id) as visit_count, json_agg(leads.id) as lead_ids").as_json
    @data = @data.select{|data| data["user_id"].present?}
    @users = current_user.manageables.calling_executives.where(id: @data.collect{|d| d["user_id"]})
    @statuses = @statuses.where(:id=>@data.collect{|d| d["status_id"]})
  end

  def ld_path q_params
    return leads_path(is_advanced_search: true, created_at_from: @start_date.to_date, created_at_upto: @end_date.to_date, :updated_at_from=>params[:updated_from], :updated_at_upto=>params[:updated_upto], :project_ids=>params[:project_ids], :source_id=>params[:source_ids], :manager_id=>params[:manager_id], :assigned_to=>params[:user_ids], :customer_type=>params[:customer_type], site_visit_done: params[:site_visit_done], site_visit_planned: params[:site_visit_planned], site_visit_cancel: params[:site_visit_cancel], revisit: params[:revisit], booked_leads: params[:booked_leads], token_leads: params[:token_leads], postponed: params[:postponed], visit_cancel: params[:visit_cancel], site_visit_from: params[:site_visit_from], site_visit_upto: params[:site_visit_upto], booking_date_from: params[:booking_date_from], booking_date_to: params[:booking_date_to], visited_date_from: params[:visited_date_from], visited_date_upto: params[:visited_date_upto], sub_source_ids: params[:sub_source_ids], sub_source: params[:sub_source], reinquired_from: params[:reinquired_from], reinquired_upto: params[:reinquired_upto], :manager_ids=>params[:manager_ids], :broker_ids=>params[:broker_ids],:visit_counts=>params[:visit_counts], **q_params)
  end

  def bl_path q_params
    return leads_path(is_advanced_search: true, created_at_from: @start_date.to_date, created_at_upto: @end_date.to_date, :updated_at_from=>params[:updated_from], :updated_at_upto=>params[:updated_upto], :project_ids=>params[:project_ids], :source_id=>params[:source_ids], :manager_id=>params[:manager_id], ncd_from: params[:ncd_from], :ncd_upto=>params[:ncd_upto], :assigned_to=>params[:user_ids], :closing_executive => params[:closing_executive], :backlogs_only=>true, customer_type: params[:customer_type], :manager_ids=>params[:manager_ids], **q_params)
  end

  def dld_path q_params
    return leads_path(is_advanced_search: true, created_at_from: @start_date.to_date, created_at_upto: @end_date.to_date, :updated_at_from=>params[:updated_from], :updated_at_upto=>params[:updated_upto], :project_ids=>params[:project_ids], :source_id=>params[:source_ids], :manager_id=>params[:manager_id], :assigned_to=>params[:user_ids], :manager_ids=>params[:manager_ids], customer_type: params[:customer_type], :lead_statuses=>current_user.company.dead_status_ids, **q_params)
  end

  def ad_path q_params
    return reports_activity_details_path(start_date: @start_date.to_date, end_date: @end_date.to_date, :project_ids=>params[:project_ids], :source_id=>params[:source_ids], :manager_id=>params[:manager_id], customer_type: params[:customer_type], :manager_ids=>params[:manager_ids], :lead_statuses=>params[:lead_statuses], **q_params)
  end

  def vd_path q_params
    return leads_path(is_advanced_search: true, visited_date_from: @start_date.to_date, visited_date_upto: @end_date.to_date, :updated_at_from=>params[:updated_from], :updated_at_upto=>params[:updated_upto], :project_ids=>params[:project_ids], :source_id=>params[:source_ids], :manager_id=>params[:manager_id], :assigned_to=>params[:user_ids], :lead_ids=>params[:lead_ids], :visit_counts=>params[:visit_counts], :visit_counts_num=>params[:visit_counts_num], customer_type: params[:customer_type], presale_user_id: params[:presale_user_id], sv_user: params[:sv_user], :manager_ids=>params[:manager_ids], **q_params)
  end

  def status_edit_html(change_entry, csv = nil)
    return "No Change" if change_entry.blank?
    if csv
      if change_entry.kind_of?(Array)
        "#{(@statuses_list.detect { |k| k['id'] == change_entry.first }['name'] rescue '')} → #{(@statuses_list.detect { |k| k['id'] == change_entry.last }['name'] rescue '')}"
      else
        "Created with Status: #{(@statuses_list.detect { |k| k['id'] == change_entry }['name'] rescue '')}"
      end
    else
      if change_entry.kind_of?(Array)
        "#{(@statuses_list.detect { |k| k['id'] == change_entry.first }['name'] rescue '')} <svg width='1em' height='1em' viewBox='0 0 16 16' class='bi bi-arrow-right' fill='currentColor' xmlns='http://www.w3.org/2000/svg'>
          <path fill-rule='evenodd' d='M10.146 4.646a.5.5 0 0 1 .708 0l3 3a.5.5 0 0 1 0 .708l-3 3a.5.5 0 0 1-.708-.708L12.793 8l-2.647-2.646a.5.5 0 0 1 0-.708z'/>
          <path fill-rule='evenodd' d='M2 8a.5.5 0 0 1 .5-.5H13a.5.5 0 0 1 0 1H2.5A.5.5 0 0 1 2 8z'/>
        </svg> #{(@statuses_list.detect { |k| k['id'] == change_entry.last }['name'] rescue '')}"
      else
        "Created with Status <b>#{(@statuses_list.detect { |k| k['id'] == change_entry }['name'] rescue '')}</b>"
      end
    end
  end


  def source_edit_html(change_entry, csv = nil)
    return "No Change" if change_entry.blank?
    if csv
      if change_entry.kind_of?(Array)
        "#{(@statuses_list.detect { |k| k['id'] == change_entry.first }['name'] rescue '')} → #{(@statuses_list.detect { |k| k['id'] == change_entry.last }['name'] rescue '')}"
      else
        "Created with Status: #{(@statuses_list.detect { |k| k['id'] == change_entry }['name'] rescue '')}"
      end
    else
      if change_entry.kind_of?(Array)
        return "#{(@sources_list.detect{|k| k['id'] == change_entry.first}['name'] rescue '')} <svg width='1em' height='1em' viewBox='0 0 16 16' class='bi bi-arrow-right' fill='currentColor' xmlns='http://www.w3.org/2000/svg'>
          <path fill-rule='evenodd' d='M10.146 4.646a.5.5 0 0 1 .708 0l3 3a.5.5 0 0 1 0 .708l-3 3a.5.5 0 0 1-.708-.708L12.793 8l-2.647-2.646a.5.5 0 0 1 0-.708z'/>
          <path fill-rule='evenodd' d='M2 8a.5.5 0 0 1 .5-.5H13a.5.5 0 0 1 0 1H2.5A.5.5 0 0 1 2 8z'/>
          </svg> #{(@sources_list.detect{|k| k['id'] == change_entry.last}['name'] rescue '')}"
      else
        return "Created with Sourc <b>#{(@sources_list.detect{|k| k['id'] == change_entry}['name'] rescue '')}</b>"
      end
    end
  end


  def user_edit_html(change_entry, csv = nil)
    return "No Change" if change_entry.blank?
    if csv
      if change_entry.kind_of?(Array)
        "#{(@statuses_list.detect { |k| k['id'] == change_entry.first }['name'] rescue '')} → #{(@statuses_list.detect { |k| k['id'] == change_entry.last }['name'] rescue '')}"
      else
        "Created with Status: #{(@statuses_list.detect { |k| k['id'] == change_entry }['name'] rescue '')}"
      end
    else
      if change_entry.kind_of?(Array)
        return "#{(@users_list.detect{|k| k['id'] == change_entry.first}['name'] rescue '')} <svg width='1em' height='1em' viewBox='0 0 16 16' class='bi bi-arrow-right' fill='currentColor' xmlns='http://www.w3.org/2000/svg'>
        <path fill-rule='evenodd' d='M10.146 4.646a.5.5 0 0 1 .708 0l3 3a.5.5 0 0 1 0 .708l-3 3a.5.5 0 0 1-.708-.708L12.793 8l-2.647-2.646a.5.5 0 0 1 0-.708z'/>
        <path fill-rule='evenodd' d='M2 8a.5.5 0 0 1 .5-.5H13a.5.5 0 0 1 0 1H2.5A.5.5 0 0 1 2 8z'/>
        </svg> #{(@users_list.detect{|k| k['id'] == change_entry.last}['name'] rescue '')}"
      else
        return "Created with User <b>#{(@users_list.detect{|k| k['id'] == change_entry}['name'] rescue '')}</b>"
      end
    end
  end

  def comment_edit_text change_entry
    return "No Change" if change_entry.blank?
    if change_entry.kind_of?(Array)
      diff = change_entry.last.to_s.sub(change_entry.first.to_s, "").strip
      return "(Added) #{diff}"
    else
      return "(Added) #{change_entry}"
    end
  end

  def sales_dashboard
    render json: {message: "This section is under maintenance until 2nd July"}, status: 200 and return
    @projects = Project.all

    @leads = Lead.includes(:project, :status, :source, :visits, :broker, :magic_attributes).to_a

    if params[:project_id].present?
      @leads = @leads.select { |lead| lead.project_id == params[:project_id].to_i }
    end

    if params[:visit_date].present?
      visit_date = Date.parse(params[:visit_date]) rescue nil
      if visit_date
        @leads = @leads.select do |lead|
          lead.visits.any? { |v| v.date.to_date == visit_date }
        end
      end
    end

    leads = @leads

    @walkin_count  = leads.count { |lead| lead.source&.name == "Walkin" }
    @booking_count = leads.count { |lead| lead.status&.name == "Booking Done" }
    @cp_count      = leads.count { |lead| lead.source&.name == "Channel Partner" }

    @channel_data = Hash[
      @leads.group_by { |lead| lead.source&.name || "Unknown" }
            .map { |channel, leads| [channel, leads.count] }
    ]

     @lead_magic_values = {}
      @leads.each do |lead|
        field_hash = lead.magic_attributes.each_with_object({}) do |ma, hash|
          key = ma.magic_field.pretty_name.downcase.strip
          hash[key] = ma.value
        end
        @lead_magic_values[lead.id] = field_hash
      end
  end





  private

  def filtered_campaigns(campaigns)
    advance_search_params = params[:advance_search]

    if advance_search_params[:start_date_from].present?
      start_date_from = Date.strptime(advance_search_params[:start_date_from], '%d/%m/%Y')
      campaigns = campaigns.where('start_date >= ?', start_date_from)
    end

    if advance_search_params[:start_date_upto].present?
      start_date_upto = Date.strptime(advance_search_params[:start_date_upto], '%d/%m/%Y')
      campaigns = campaigns.where('start_date <= ?', start_date_upto)
    end

    if advance_search_params[:end_date_from].present?
      end_date_from = Date.strptime(advance_search_params[:end_date_from], '%d/%m/%Y')
      campaigns = campaigns.where('end_date >= ?', end_date_from)
    end

    if advance_search_params[:end_date_upto].present?
      end_date_upto = Date.strptime(advance_search_params[:end_date_upto], '%d/%m/%Y')
      campaigns = campaigns.where('end_date <= ?', end_date_upto)
    end

    if advance_search_params[:project_id].present?
      project_ids = advance_search_params[:project_id]&.map(&:to_i)
      campaigns = campaigns.joins(:projects).where(projects: { id: project_ids })
    end

    campaigns
  end

  def set_start_end_date
    start_offset = 7
    @start_date = params[:start_date].present? ? Time.zone.parse(params[:start_date]).beginning_of_day : (Time.zone.now - start_offset.day).beginning_of_day
    @end_date = params[:end_date].present? ? Time.zone.parse(params[:end_date]).end_of_day : Time.zone.now.end_of_day
  end

  def set_company_props
    company = current_user.company
    @leads = company.leads
    @sources = company.sources
    if current_user.is_marketing_manager?
      @leads=@leads.where(source_id: current_user.accessible_sources.ids) if current_user.is_marketing_manager?
      @sources = current_user.accessible_sources
    end
    @statuses = company.statuses.latest_first
    @sub_sources=company.sub_sources
    @projects = company.projects
  end

  def activity_search_params
    params.permit(:customer_type, :manager_id, :source_ids=>[], :project_ids=>[], :lead_statuses=>[], manager_ids: [])
  end

  def visit_params
    params.permit(:customer_type, :visit_counts, :visit_counts_num, :manager_id, :project_ids=>[], :source_ids=>[], :presale_user_id=>[], :manager_ids=>[])
  end

  def site_visit_tracker_params
    params.permit(:revisit, :site_visit_planned, :site_visit_done, :site_visit_cancel, :booked_leads, :customer_type, :site_visit_from, :site_visit_upto, :token_leads, :visit_cancel, :postponed)
  end

  def set_base_leads
    @leads = @leads.where(:created_at=>@start_date..@end_date)
    unless current_user.is_super?
      @leads = @leads.where("leads.user_id IN (:user_ids) or leads.closing_executive IN (:user_ids)", :user_ids=>current_user.manageable_ids)
    end
    @leads = @leads.filter_leads_for_reports(params, current_user)
  end

  def call_log_report_params
    params.permit(
      :call_direction, 
      :start_date, 
      :end_date, 
      :todays_calls, 
      :completed, 
      :abandoned_calls, 
      :missed_calls, 
      :lead_name,
      :call_from,
      :call_to,
      :updated_from,
      :updated_upto,
      source_ids: [],
      lead_statuses: [],
      user_ids: [],
      broker_ids: [],
      project_ids: [],
      call_status: [],
      abandoned_calls_status: []
    )
  end

  def status_dashboard_params
    params.permit(:manager_id, :visited, :site_visit_from, :site_visit_upto, project_ids: [], lead_statuses: [], manager_ids: [])
  end

  def user_call_reponse_search
    params.permit(
      :start_date,
      :end_date,
      project_ids: []
    )
  end

end
