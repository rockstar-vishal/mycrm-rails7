class LeadsController < ApplicationController
  include MagicFieldsPermittable
  before_action :set_leads
  before_action :set_lead, only: [:show, :delete_visit, :make_call,:new_visit, :create_visit, :edit, :update, :destroy, :histories, :edit_visit, :deactivate, :print_visit]

  respond_to :html
  PER_PAGE = 20

  def index
    @users = current_user.manageables
    if params[:is_advanced_search].present? || params[:search_query].present?
      if @company.remove_closed?
        if params[:lead_statuses].present?
          @leads = @leads.search_base_leads(current_user)
        else
          @leads = @leads.user_leads(current_user)
        end
      else
        @leads = @leads.search_base_leads(current_user)
      end
    else
      @leads = @leads.user_leads(current_user)
    end
    if params[:is_advanced_search].present? && params[:search_query].blank?
      if params["save_search_id"].present?
        @leads = @leads.advance_search(current_user.search_histories.find(params[:save_search_id]).search_params, current_user)
      else
        @leads = @leads.advance_search(search_params, current_user)
        if params["search_name"].present? && params["set_search"].present?
          @search_history = @leads.save_search_history(search_params, current_user, params["search_name"])
        end
      end
    end

    if params[:search_query].present?
      @leads = @leads.basic_search(params[:search_query], current_user, options={backlogs_only: params[:backlogs_only]})
    end
    if params[:showable_ids_cs].present?
      @leads = @leads.where(:id=>params[:showable_ids_cs].split(",").uniq)
    end
    if params["key"].present? && params["sort"].present?
      if params["key"] == 'project_id'
        @leads = @leads.includes(:project).order("projects.name #{params['sort']} NULLS FIRST")
      elsif params["key"] == 'status_id'
        @leads = @leads.includes(:status).order("statuses.name #{params['sort']} NULLS FIRST")
      else
        if @company.setting.present? && @company.enable_ncd_sort_nulls_last && params['sort'] == "desc"
          @leads = @leads.order("leads.#{params['key']} #{params['sort']} NULLS LAST")
        else
          @leads = @leads.order("leads.#{params['key']} #{params['sort']} NULLS FIRST")
        end
      end
    else
      @leads = @leads.order("leads.ncd asc NULLS FIRST, leads.created_at DESC")
    end
    @leads_count = @leads.size
    respond_to do |format|
      format.html do
        @leads = @leads.includes(:user, :status, :project, :source, :visits, :broker).paginate(:page => params[:page], :per_page => PER_PAGE)
      end
      format.csv do
        if @leads_count <= 4000
          current_user.company.export_logs.create(user_id: current_user.id, ip_address: request.remote_ip, count: @leads_count)
          send_data @leads.includes(:user, :status, :project, :source, :visits).to_csv({}, current_user), filename: "leads_#{Date.today.to_s}.csv"
        else
          render json: {message: "Export of more than 4000 leads is not allowed in one single attempt. Please contact management for more details"}, status: 403
        end
      end
      format.js do
        current_user.export_logs.create(
          target_ids: @leads.ids,
          target_type: 'Lead',
          count: @leads_count,
          company_id: current_user.company_id
        )

        render_modal('process_lead_export_csv')
      end
    end
  end

  def calender_view
    start_offset = 60
    if params[:is_advanced_search].present?
      @leads = @leads.advance_search(search_params, current_user)
    end
    respond_to do |format|
      format.html
      format.json do
        @leads = @leads.user_leads(current_user)
        @start_date = params[:start].present? ? Time.zone.parse(params[:start]).beginning_of_day : (Time.zone.now).beginning_of_day
        @end_date = params[:end].present? ? Time.zone.parse(params[:end]).end_of_day : (Time.zone.now + start_offset.day).end_of_day
        @leads = @leads.where("leads.ncd BETWEEN ? AND ?", @start_date.to_date, @end_date.to_date)
        render json: @leads.as_api_response(:lead_event)
      end
    end
  end

  def bulk_action
    @leads = @leads.where(id: params[:lead_ids])
    if params["button"] == "send_email_to_team"
      send_lead_details
    elsif params["button"] == "delete"
      @leads.each do |l|
        l.destroy
      end
      flash[:danger] = "Selected leads deleted"
    elsif params["button"] == "deactivate"
      @leads.each do |l|
        l.deactivate
      end
      flash[:danger] = "Selected leads deactivated"
    elsif params["button"] == 'bulk_call'
      @leads.initiate_bulk_call(current_user)
      flash[:notice] = 'Selected Leads Call Initiated'
    else
      @leads.each do |lead|
        lead.user_id = params["assigned_to"].present? ? params["assigned_to"] : lead.user_id
        lead.closing_executive = params["closing_executive"].present? ? params["closing_executive"] : lead.closing_executive
        lead.status_id = params["lead_status"].present? ? params["lead_status"] : lead.status_id
        lead.source_id = params["lead_source"].present? ? params["lead_source"] : lead.source_id
        lead.ncd = params["ncd"].present? ? Time.zone.parse(params["ncd"]) : lead.ncd
        lead.project_id = params["project_id"].present? ? params["project_id"] : lead.project_id
        lead.save
      end
      flash[:success] = "Selected leads are updated."
    end
    redirect_to request.referer
  end

  def send_lead_details
    email_lists = current_user.manageables.where(id: params[:email_to]).pluck(:email)
    mail_params = {subject: params[:subject], message: params[:message]}
    if email_lists.present?
      if mail_params[:subject].blank?
        flash[:danger] = "Please add subject for sending the email!"
      else
        UserMailer.share_lead_details_on_email(current_user, email_lists, @leads, mail_params).deliver!
        flash[:notice] = "Email sent Successfully!"
      end
    else
      flash[:success] = "Please select email from the email lists!"
    end
  end


  def show
    @default_tab = params[:tab] || 'leads-detail' 
    render_modal('show', {:class=>'right'})
  end

  def new_visit
    @visits = @lead.visits.build
    render_modal('site_visit_form')
  end

  def create_visit
    @default_tab = 'site-visit-detail'
    if @lead.update(lead_params)
      flash[:notice] = 'Visit Detail Updated Successfully'
      if current_user.is_supervisor?
        render_modal("onsite_leads/visit_detail", {class: 'right'})
      else
        render_modal('show', {:class=>'right'})
      end
    else
      # Only show the visit that was being added, not all visits
      # Find the visit that was being added (the one with validation errors)
      @visits = @lead.visits.select { |v| v.new_record? || v.errors.any? }.first || @lead.visits.build
      render_modal('site_visit_form')
    end
  end

  def delete_visit
    @default_tab = "site-visit-detail"
    @visit = @lead.visits.find(params[:visit_id])
    if @visit.destroy
      respond_to do |format|
        format.js { render js: "// Visit deleted successfully" }
        format.html { redirect_to leads_path, notice: "Visit Deleted Successfully" }
      end
    else
      respond_to do |format|
        format.js { render js: "alert('Error deleting visit');" }
        format.html { redirect_to leads_path, alert: "Error deleting visit" }
      end
    end
  end

  def new
    @lead = @leads.new
    if params[:lead_id].present?
      lead = @leads.find(params[:lead_id])
      @lead.assign_attributes(
        name: lead.name,
        email: lead.email,
        mobile: lead.mobile,
        status_id: lead.status_id,
        city_id: lead.city_id,
        locality_id: lead.locality_id)
    end
  end

  def edit
    respond_to do |format|
      format.js do
        render_modal('edit')
      end
      format.html
    end
  end

  def create
    # Separate magic fields from regular attributes
    regular_params, magic_params = Lead.separate_magic_fields(@company, lead_params)
    
    @lead = @leads.new
    @lead.assign_attributes(regular_params)
    
    # Set magic fields using dynamic setters
    magic_params.each do |key, value|
      @lead.send("#{key}=", value) if @lead.respond_to?("#{key}=")
    end
    
    unless @lead.company.round_robin_enabled?
      @lead.user_id = current_user.id if @lead.user_id.blank?
    end
    if @lead.save
      flash[:notice] = "Lead Created Successfully"
      redirect_to leads_path and return
    else
      render 'new'
    end
  end

  def update
    is_save = @lead.update(lead_params)
    respond_to do |format|
      format.js do
        if is_save
          flash[:notice] = "Lead Updated Successfully"
          xhr_redirect_to redirect_to: request.referer
        else
          render_modal 'edit'
        end
      end
      format.html do
        if is_save
          flash[:notice] = "Lead Updated Successfully"
          redirect_to leads_path
        else
          render 'edit'
        end
      end
    end
  end

  def destroy
    if @lead.destroy
      flash[:success] = "Lead Deleted Successfully"
    else
      flash[:danger] = "Cannot Delete this Lead - #{@lead.errors.full_messages.join(', ')}"
    end
    redirect_to leads_path and return
  end

  def edit_visit
    @visits=@lead.visits.find(params[:visit_id])
    render_modal('site_visit_form')
  end

  def print_visit
    @visit=@lead.visits.find(params[:visit_id])
    respond_to do |format|
      format.pdf do
        render pdf: "sv_#{@visit.date.strftime('%d-%m-%y')}",
              template: "leads/visit_pdf.html.haml",
              locales: {:@lead=> @lead, :@visit => @visit},
              :print_media_type => true
      end
    end
  end

  def perform_import
    if params[:lead_file].present?
      file = params[:lead_file].tempfile
      @success=[]
      @errors=[]
      mf_names = @company&.magic_fields&.pluck(:name) || []
      CSV.foreach(file, headers: :first_row, encoding: "iso-8859-1:utf-8") do |row|
        begin
          name=row["Name"]
          mobile=row["Phone"]
          email= row["Email"]
          address = row["Address"]
          other_phones=row["Other Contacts"]
          sub_source = row["Sub Source"]&.strip
          lead_status_id=(@company.statuses.find_id_from_name(row["Lead Status"].strip) rescue nil)
          next_call_date_and_time = Time.zone.parse(row["Next Call Date"].strip) rescue nil
          user_id = (current_user.manageables.find_by_email(row["Assigned To"].strip).id rescue nil)
          project_id = (@company.projects.find_id_from_name(row["Enquiry"].strip) rescue nil)
          source_id = (@company.sources.active.find_id_from_name(row["Lead Source"]) rescue nil)
          broker_id = (@company.brokers.find_by(uuid: row["Channel Partner(CP UUID)"]).id rescue nil)
          city_id = (City.find_id_from_name(row["City"]) rescue nil)
          closing_executive = (current_user.manageables.meeting_executives.find_by_email(row["Closing Executive"].strip).id rescue nil)
          comment = row["Description"]
          if row["Dead Reason"].present?
            dead_reason = (@company.find_dead_reason(row["Dead Reason"].strip) rescue nil)
            dead_reason_id = dead_reason&.id
            dead_sub_reason=row["Dead Sub Reason"].strip rescue nil
          end
          referal_name=@company.referal_sources.ids.include?(source_id) ? row["Referal Name"]&.strip : nil
          referal_mobile=@company.referal_sources.ids.include?(source_id) ? row["Referal Mobile"]&.strip : nil
          locality_id = (Locality.find_id_from_name(row["Locality"]) rescue nil)
          created_at = Time.zone.parse(row["Created at"].strip) rescue nil
          tentative_visit_planned = Time.zone.parse(row["Tentative Visit Date"].strip) rescue nil
          stage = @company.company_allowed_stages.where("name ILIKE ?", row["Lead Stage"]&.strip).last
          lead = @leads.new(
            name: name,
            mobile: mobile,
            other_phones: other_phones,
            email: email,
            status_id: lead_status_id,
            address: address,
            user_id: user_id,
            project_id: project_id,
            source_id: source_id,
            actual_comment: comment,
            ncd: next_call_date_and_time,
            broker_id: broker_id,
            city_id: city_id,
            locality_id: locality_id,
            dead_reason_id: dead_reason_id,
            dead_sub_reason: dead_sub_reason,
            created_at: created_at,
            referal_mobile: referal_mobile,
            referal_name: referal_name,
            closing_executive: closing_executive,
            tentative_visit_planned: tentative_visit_planned,
            presale_stage_id: stage&.id
          )
          if row["Visited"] == "Yes"
            if row["Visits"].present?
              visits = row["Visits"].to_s.strip.split("||")
              visits.each do |visit_item|
                date, comment = visit_item.split("::")
                lead.visits.build(date: date, comment: comment)
              end
            elsif row["Visited Date"].present?
              visited_dates = row["Visited Date"].to_s.strip.split(",")
              visited_dates.each do |visit_date|
                lead.visits.build(date: (Date.parse(visit_date) rescue nil))
              end
            end
          end
          mf_names.each do |mf_name|
            lead.send("#{mf_name}=", row[mf_name.camelize].to_s.strip)
          end
          if @company.is_allowed_field?('enquiry_sub_source_id')
            lead.enquiry_sub_source_id = (@company.sub_sources.find_id_from_name(sub_source) rescue nil)
          else
            lead.sub_source = sub_source
          end
          lead.cannot_send_notification = true
          if lead.save
            @success << {lead_name: row["Name"], message: "Success"}
          else
            @errors << {lead_name: row["Name"], message: lead.errors.full_messages.join(" | ")}
          end
        rescue Exception => e
          @errors << {lead_name: row["Name"], message: "#{e}"}
        end
      end
    else
      flash[:danger] = "Please upload CSV file."
      redirect_to leads_path
    end
  end

  def import
  end

  def prepare_bulk_update
  end

  def import_bulk_update
    @success = []
    @errors = []
    mf_names = @company&.magic_fields&.pluck(:name) || []
    if params[:leads_file].present?
      csv_data = CSV.read(params[:leads_file].tempfile, headers: :first_row, encoding: "iso-8859-1:utf-8")
      if csv_data.count > 1000
        flash[:alert] = "You can only import up to 50 leads at a time."
        redirect_to prepare_bulk_update_leads_path and return
      end

      csv_data.each do |row|
        if row["Delete"].present? && row["Delete"] == "YES"
          lead = current_user.company.leads.find_by(lead_no: row["Lead No"]) rescue nil
          if lead.present?
            if lead.destroy
              @success << {lead_no: row["Lead No"], :message=>"Lead Deleted Successfully"}
            else
              @errors << {lead_no: row["Lead No"], :message=>"#{lead.errors.full_messages}"}
            end
          else
            @errors << {lead_no: row["Lead No"], :message=>"Lead Not Found"}
          end
        else
          lead_no = row["Lead No"].strip rescue nil
          lead_comment = row["Comment"].strip rescue nil
          lead_status_id=(@company.statuses.of_leads.find_id_from_name(row["Lead Status"].strip) rescue nil)
          lead_stage_id = (Stage.where(id: (@company.company_stages.pluck(:stage_id))).find_id_from_name(row["Lead Stage"].strip) rescue nil)
          user_id = (current_user.manageables.find_by_email(row["Assigned To"].strip).id rescue nil)
          closing_executive = (current_user.manageables.meeting_executives.find_by_email(row["Sale Manager"].strip).id rescue nil)
          dead_reason = (@company.find_dead_reason(row["Dead Reason"].strip) rescue nil)
          source_id = (@company.sources.active.find_id_from_name(row["Lead Source"]) rescue nil)
          lead_next_call_date = (Time.zone.parse(row["Next Call Date"].strip) rescue nil)
          project_id = (@company.projects.find_id_from_name(row["Enquiry"].strip) rescue nil)
          created_at = (Time.zone.parse(row["Created at"].strip) rescue nil)
          address = row["Address"].strip rescue nil
          begin
            lead = @leads.find_by_lead_no(lead_no)
            if lead.present?
              if lead_comment.present?
                lead.comment = lead_comment
              end
              lead.status_id = lead_status_id.present? ? lead_status_id : lead.status_id
              lead.source_id = source_id.present? ? source_id : lead.source_id
              lead.dead_reason_id = dead_reason.present? ? dead_reason.id : lead.dead_reason_id
              lead.ncd = lead_next_call_date.present? ? lead_next_call_date : lead.ncd
              lead.user_id = user_id.present? ? user_id : lead.user_id
              lead.closing_executive=closing_executive.present? ? closing_executive : lead.closing_executive
              lead.presale_stage_id = lead_stage_id.present? ? lead_stage_id : lead.presale_stage_id
              lead.project_id = project_id.present? ? project_id : lead.project_id
              lead.created_at = created_at.present? ? created_at : lead.created_at
              lead.address = address
              mf_names.each do |mf_name|
                lead.send("#{mf_name}=", row[mf_name.camelize].to_s.strip.present? ? row[mf_name.camelize].to_s.strip : lead.send("#{mf_name}"))
              end
              if lead.save
                @success << {lead_no: row["Lead No"], :message=>"Success"}
              else
                @errors << {lead_no: row["Lead No"], :message=>"#{lead.errors.full_messages}"}
              end
            else
              @errors << {lead_no: row["Lead No"], :message=>"Lead Not Found"}
            end
          rescue Exception => e
            @errors << {:lead_no=>row["Lead No"], :message=>"#{e}"}
          end
        end
      end
    else
      flash[:alert] = "Please upload CSV file."
      redirect_to prepare_bulk_update_leads_path
    end
  end

  def histories
    @lead_logs = @lead.audits.order(created_at: :desc)
    @lead_call_attempts = @lead.call_attempts.includes(:user).order(updated_at: :desc)
  end

  def make_call
    status, message = @lead.make_call current_user
    if status
      render json: {success: true}, status: 200 and return
    else
      render json: {success: false, message: message}, status: 400 and return 
    end
  end

  def call_logs
    @call_logs = @company.call_logs.joins(:lead).where(leads: {user_id: current_user.manageables.ids})
    if params[:is_external].present?
      @call_logs = @call_logs.advance_search(call_logs_search_params)
    elsif params[:is_advanced_search].present?
      if params[:call_log_report].present?
        @call_logs = @call_logs.advance_search(call_logs_search_params)
      else
        @call_logs = @call_logs.incoming
        @call_logs = @call_logs.advance_search(call_logs_search_params)
      end
    else
      @call_logs = @call_logs.incoming
      @call_logs = @call_logs.advance_search(call_logs_search_params)
    end

    respond_to do |format|
      format.html do
        @call_logs = @call_logs.order("leads_call_logs.start_time DESC").paginate(:page => params[:page], :per_page => PER_PAGE)
      end
      format.csv do
        @call_logs = @call_logs.order("leads_call_logs.start_time DESC")
        send_data @call_logs.call_logs_csv({}, current_user), filename: "communication_logs#{Date.today.to_s}.csv"
      end
    end
  end

  def download_call_log_recording
    @call_log = @company.call_logs.find_by(id: params[:call_log_id])
    recording_url = @call_log.recording_url
    filename = File.basename(URI.parse(recording_url).path)
    send_data open(recording_url).read, type: 'audio/mp3', filename: filename
  end

  def outbound_logs
    @call_logs = @company.call_logs.not_incoming.where(user_id: current_user.manageables.ids)
    if params[:is_advanced_search].present?
      @call_logs = @call_logs.advance_search(outbound_search_params)
    else
      @call_logs = @call_logs
    end

    respond_to do |format|
      format.html do
        @call_logs = @call_logs.order("leads_call_logs.updated_at DESC").paginate(:page => params[:page], :per_page => PER_PAGE)
      end
      format.csv do
        @call_logs = @call_logs.order("leads_call_logs.updated_at DESC")
        send_data @call_logs.call_logs_csv({}, current_user), filename: "outbound_logs#{Date.today.to_s}.csv"
      end
    end
  end

  def dead_or_recycle
    @leads = @leads.joins(:audits).where("((audits.audited_changes -> 'status_id')::jsonb->>1)::INT IN (?)", @company.dead_status_ids.map(&:to_i)).select("DISTINCT ON (audits.associated_id) leads.*")
    if params[:is_advanced_search].present?
      @leads = @leads.advance_search(search_params, current_user)
    end
    @leads = @leads.where(user_id: current_user.manageables.ids).paginate(:page => params[:page], :per_page => PER_PAGE)
  end

  def lead_counts
    @leads = current_user.manageable_leads
    today_calls_count=@leads.active_for(current_user.company).todays_calls.count
    backlog_leads_count = @leads.backlogs_for(@company).count
    hot_status_count = @leads.where(status_id: @company.hot_status_ids).count
    new_status_count = @leads.where(status_id: @company.new_status_id).count
    booking_done_count = @leads.where(status_id: @company.booking_done_id).count
    dead_lead_count = @leads.where(status_id: @company.dead_status_ids).count
    visit_counter = @leads.joins(:visits).thru_visit_form(current_user.company).uniq.count
    deactivate_leads_count=@leads.unscoped.where(is_deactivated: true).count
    merge_lead_count=@leads.joins(:leads_secondary_sources).pluck(:id).uniq.count
    visit_expiration_count=@leads.visit_expiration.size
    respond_to do |format|
      format.json do
        render json: {hot_status_count: hot_status_count, new_status_count: new_status_count, booking_done_count: booking_done_count, dead_lead_count: dead_lead_count, today_calls_count: today_calls_count, backlog_leads_count: backlog_leads_count, merge_lead_count: 
        merge_lead_count, visit_counter: visit_counter, deactivate_leads_count: deactivate_leads_count, visit_expiration_count: visit_expiration_count, status: 200}
      end
    end
  end

  def deactivate
    @lead.deactivate
    redirect_to leads_path and return
  end

  def activate
    leads=@leads.unscoped.where(is_deactivated: true)
    @lead=leads.find(params[:id])
    @lead.activate
    redirect_to leads_path and return
  end

  def stages
    @status = @company.statuses.find_by(id: params[:status_id])
    company_stages = @status.fetch_stages(@company).as_api_response(:details)
    render json: company_stages, status: 200 and return
  end

  def localities
    localities = Locality.joins(region: [:city]).where("cities.id=?", params[:id]).as_json(only: [:id, :name])
    render json: localities, status: 200 and return
  end

  def fetch_source_subsource
    sub_sources=@company.sub_sources
    if @company.setting.present? && @company.enable_source_wise_sub_source
      sub_sources=sub_sources.joins(:source).where("sources.id=?",params[:id]).as_json(only: [:id, :name])
    end
    render json: sub_sources, status: 200 and return
  end

    def set_lead
      @lead = @leads.find(params[:id])
    end

    def set_leads
      Lead.current_user = current_user
      @company = current_user.company
      @leads = @company.leads
    end

    def lead_params
      standard_lead_params(@company)
    end

    def search_params
      search_params_with_magic_fields(@company)
    end
    helper_method :search_params

    def call_logs_search_params
      params.permit(
        :past_calls_only,
        :todays_calls,
        :missed_calls,
        :created_at_from,
        :created_at_upto,
        :completed,
        :abandoned_calls,
        :display_from,
        :start_date,
        :end_date,
        :call_direction,
        :first_call_attempt,
        :lead_name,
        :call_from,
        :call_to,
        source_ids: [],
        lead_statuses: [],
        lead_ids: [],
        user_ids: [],
        broker_ids: [],
        project_ids: [],
        call_status: [], # convert string to array
        abandoned_calls_status: []
      )
    end
    helper_method :call_logs_search_params

    def outbound_search_params
      params.permit(
        :missed_calls,
        :todays_calls,
        :past_calls_only,
        :created_at_from,
        :created_at_upto,
        :updated_from,
        :updated_upto,
        :lead_name,
        :call_from,
        :call_to,
        source_ids: [],
        lead_statuses: [],
        user_ids: [],
        project_ids: [],
        broker_ids: [],
        call_status: [] # convert string to array
      )
    end
    helper_method :outbound_search_params

    def histories_params
      params.permit(:sort, :key, :incoming)
    end
    helper_method :histories_params
end
