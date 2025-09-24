class CompaniesController < ApplicationController
  before_action :set_company, only: [:show, :edit, :update, :destroy, :fb_pages, :prepare_import_fb_pages, :import_fb_pages, :shuffle_statues_form, :update_status_order, :broker_form, :project_form, :sv_form, :renewals, :update_sv_form, :mobile_logo_form]
  before_action :build_configuration_attributes, only: :edit

  respond_to :html

  PER_PAGE = 20

  def index
    @companies = Company.all
    if params[:search_query].present?
      @companies = @companies.basic_search(params[:search_query])
    end
    if params[:is_advanced_search].present?
      @companies = @companies.advance_search(advance_search_params)
    end
    respond_to do |format|
      format.html do
        @companies = @companies.paginate(:page => params[:page], :per_page => PER_PAGE)
      end
      format.csv do
        send_data @companies.to_csv({}), filename: "company_details_#{Date.today.to_s}.csv"
      end
    end
  end

  def fb_pages
    @fb_pages = @company.fb_pages
  end

  def prepare_import_fb_pages

  end

  def import_fb_pages
    if params[:lead_file].present?
      file = params[:lead_file].tempfile
      @success=[]
      @errors=[]
      CSV.foreach(file, headers: :first_row, encoding: "iso-8859-1:utf-8") do |row|
        arr_row = row.to_a
        token = arr_row.first.last
        title = row["name"]
        page_fbid = row["id"]
        begin
          extend_res = FbSao.extend_token(token).last
          if extend_res["error"].present?
            @errors << {name: title, error: extend_res["error"]}
          else
            if extend_res['access_token'].present?
              extended_token = extend_res['access_token']
              fb_page = @company.fb_pages.build(title: title, page_fbid: page_fbid, access_token: extended_token)
              if fb_page.save
                @success << "#{title} Created"
              else
                @errors << {name: title, error: fb_page.errors.full_messages.join(', ')}
              end
            end
          end
        rescue Exception => e
          error_message = "#{e.backtrace[0]} --> #{e}"
          @errors << {:name=>title, :message=>error_message}
        end
      end
    end
  end

  def show
    render_modal('show', {:class=>'right'})
  end

  def new
    @company = Company.new
    build_configuration_attributes
  end

  def edit
  end

  def create
    @company = Company.new(company_params)
    if @company.save
      flash[:notice] = "Company Created Successfully"
      redirect_to companies_path
    else
      render 'new'
    end
  end

  def update
    # Filter out unwanted magic_fields updates
    filtered_params = filter_magic_fields_params(company_params)
    
    if @company.update(filtered_params)
      flash[:notice] = "Company Updated Successfully"
      redirect_to companies_path
    else
      render 'edit'
    end
  end

  def destroy
    @company.destroy
    respond_with(@company)
  end

  def mobile_logo_form
    @company.build_mobile_crm_logo if @company.mobile_crm_logo.blank?
  end

  def shuffle_statues_form
  end

  def update_status_order
    if params[:status][:order].present?
      status_ids = params[:status][:order]
      status_ids.map(&:to_i).each do |status_id|
        @company.company_statuses.where(status_id: status_id)&.last.update_columns(order: status_ids.index(status_id.to_s))
      end
      flash[:notice] = "Statuses shuffled successfully."
      redirect_to companies_path
    end
  end

  def broker_form
    @company.build_broker_configuration if @company.broker_configuration.blank?
  end

  def sv_form
    @company.build_sv_form if @company.sv_form.blank?
    @magic_fields=@company.magic_fields
  end

  def update_sv_form
    if @company.update(company_params)
      if params[:keys].present? && params[:values].present?
        sv_form = @company.sv_form || @company.build_sv_form
        other_data = {}
        params[:keys].each_with_index do |key, index|
          value = params[:values][index]
          if key.present? && value.present?
            other_data[key] = value
          end
        end
        if sv_form.other_data.present?
          sv_form.other_data={}
        end
        sv_form.other_data = other_data
        sv_form.save
      end
      flash[:notice] = "Company Updated Successfully"
      redirect_to companies_path
    else
      render :sv_form
    end
  end

  def renewals
  end

  def project_form
    @company.build_project_configuration if @company.project_configuration.blank?
  end

  private


    def build_configuration_attributes
      @company.build_push_notification_setting if @company.push_notification_setting.blank?
      @company.build_exotel_integration if @company.exotel_integration.blank?
      @company.build_mcube_integration if @company.mcube_integration.blank?
      @company.build_sms_integration if @company.sms_integration.blank?
      @company.build_mailchimp_integration if @company.mailchimp_integration.blank?
      @company.build_knowrality_integration if @company.knowrality_integration.blank?
      @company.build_tatatele_integration if @company.tatatele_integration.blank?
      @company.build_slashrtc_integration if @company.slashrtc_integration.blank?
      @company.build_smtp_integration if @company.smtp_integration.blank?
      @company.build_value_first_integration if @company.value_first_integration.blank?
      @company.build_whatsapp_integration if @company.whatsapp_integration.blank?
      @company.build_setting if @company.setting.blank?
      @company.build_callerdesk_integration if @company.callerdesk_integration.blank?
      @company.build_teleteemtech_integration if @company.teleteemtech_integration.blank?
    end

    def set_company
      @company = Company.find(params[:id])
    end
    
    def filter_magic_fields_params(params)
      # Only allow items to be updated if is_select_list is true
      if params[:magic_fields_attributes].present?
        params[:magic_fields_attributes].each do |index, magic_field_params|
          if magic_field_params[:is_select_list] != '1' && magic_field_params[:is_select_list] != true
            # Remove items from params if is_select_list is not checked
            Rails.logger.info "Filtering out items for magic_field #{magic_field_params[:id]} - is_select_list is #{magic_field_params[:is_select_list]}"
            magic_field_params.delete(:items)
          else
            # Convert items string to proper array format
            if magic_field_params[:items].is_a?(String) && magic_field_params[:items].present?
              Rails.logger.info "Converting items string: #{magic_field_params[:items]}"
              # Split by comma, strip whitespace, and filter out empty values
              items_array = magic_field_params[:items].split(',').map(&:strip).reject(&:blank?)
              Rails.logger.info "Converted to array: #{items_array.inspect}"
              magic_field_params[:items] = items_array
            end
          end
        end
      end
      
      # Also filter structure_fields_attributes
      if params[:sv_form_attributes] && params[:sv_form_attributes][:structure_fields_attributes].present?
        params[:sv_form_attributes][:structure_fields_attributes].each do |index, structure_field_params|
          if structure_field_params[:is_select_list] != '1' && structure_field_params[:is_select_list] != true
            # Remove items from params if is_select_list is not checked
            Rails.logger.info "Filtering out items for structure_field #{structure_field_params[:id]} - is_select_list is #{structure_field_params[:is_select_list]}"
            structure_field_params.delete(:items)
          else
            # Convert items string to proper array format
            if structure_field_params[:items].is_a?(String) && structure_field_params[:items].present?
              Rails.logger.info "Converting structure items string: #{structure_field_params[:items]}"
              # Split by comma, strip whitespace, and filter out empty values
              items_array = structure_field_params[:items].split(',').map(&:strip).reject(&:blank?)
              Rails.logger.info "Converted to array: #{items_array.inspect}"
              structure_field_params[:items] = items_array
            end
          end
        end
      end
      
      params
    end

    def company_params
      params.require(:company).permit(
        :name,
        :description,
        :domain,
        :mobile_domain,
        :partner_crm_url,
        :postsale_url,
        :sms_mask,
        :expected_site_visit_id,
        :site_visit_done_id,
        :booking_done_id,
        :new_status_id,
        :logo,
        :icon,
        :favicon,
        :default_from_email,
        :users_count,
        :rejection_reasons,
        :requirement,
        :remove_closed,
        :round_robin_enabled,
        closing_executive_trigger_statuses: [],
        expected_visit_ids: [],
        hot_status_ids: [],
        dead_status_ids: [],
        customize_report_status_ids: [],
        cost_sheet_letter_types: [],
        token_status_ids: [],
        popup_fields: [],
        allowed_fields: [],
        index_fields: [],
        visits_allowed_fields: [],
        status_ids: [],
        source_ids: [],
        events: [],
        required_fields: [],
        restricted_lead_fields: [],
        card_status: [],
        reasons_attributes: [:id, :_destroy, :reason, :active],
        role_statuses_attributes: [
          :id,
          :role_id,
          :_destroy,
          status_ids: []
        ],
        broker_configuration_attributes: [
        :id,
        {
          required_fields: [],
        }],
        project_configuration_attributes: [
          :id,
          allowed_fields: []
        ],
        mobile_crm_logo_attributes: [
          :id, 
          :small_icon,
          :large_icon,
          :small_maskable_icon,
          :large_maskable_icon,
          :apple_icon,
          :tile_image,
          :masked_icon,
          :large_favicon,
          :er_sm_logo
        ],
        sv_form_attributes: [
          :id,
          :company_id,
          :title,
          :domain,
          :bg_color,
          :primary_color,
          :seperate_firm_name_broker_name,
          :hide_image_upload_option,
          :break_name_field,
          :sv_logo,
          :dark_color_fix,
          :key,
          :otp_type,
          :otp_url,
          :request_method,
          :enable_otp,
          :other_data,
          disabled_sv_fields: [],
          structure_fields_attributes: [
            :id,
            :name,
            :section_heading,
            :label,
            :is_select_list,
            :is_required,
            :print_enabled,
            :field_position,
            :_destroy,
            :items
          ]
        ],
        setting_attributes: [
          :id,
          :can_show_lead_phone,
          :global_validation,
          :hide_next_call_date,
          :project_wise_round_robin,
          :can_assign_all_users,
          :call_response_report,
          :biz_integration_enable,
          :client_integration_enable,
          :broker_integration_enable,
          :enable_email_action,
          :enable_whatsapp_action,
          :enable_lead_tracking,
          :enable_callerdesk_sid,
          :enable_presale_user_visits_report,
          :czentrixcloud_enable,
          :visit_filter_enable,
          :secondary_level_round_robin,
          :back_dated_ncd_allowed,
          :edit_profile_not_allowed,
          :enable_lead_direct_edit,
          :enable_call_center_dashboard,
          :default_lead_user_enable,
          :enable_broker_management,
          :hide_lead_mobile_for_executive,
          :can_send_lead_assignment_mail,
          :way_to_voice_enabled,
          :enable_executive_export_leads,
          :set_svp_default_7_days,
          :enable_booking_done_fields,
          :enable_executive_to_assign_users,
          :enable_country_in_project,
          :enable_managerwise_report,
          :enable_cards_on_advance_search,
          :enable_advance_visits,
          :disable_visit_finance_section,
          :enable_site_visit_planned_tracker,
          :enable_ncd_sort_nulls_last,
          :set_ncd_non_mandatory_for_booked_status,
          :enable_meeting_executives,
          :can_clone_lead,
          :can_add_users,
          :enable_lead_log_export,
          :fb_campaign_enabled,
          :project_campaign_enabled,
          :managerwise_closing_executive_active,
          :inventory_integration_enable,
          :restrict_sv_form_duplicate_lead_visit,
          :can_delete_users,
          :open_closed_lead_enabled,
          :mobicomm_sms_service_enabled,
          :is_sv_project_enabled,
          :enable_sub_source_report,
          :enable_booking_loan_fields,
          :enable_marketing_report_subsource_filter,
          :enable_source,
          :my_sms_shop_enabled,
          :pg_sms_api_enabled,
          :exotel_sms_integration_enabled,
          :enable_smtp_settings,
          :template_flag_name,
          :sms360_enabled,
          :enable_user_incentive,
          :enable_visit_counter_card,
          :enable_flat_details,
          :closing_executive_round_robin,
          :enable_broker_bulk_update,
          :enable_import_brokers,
          :enable_export_brokers,
          :enable_source_wise_report,
          :enable_status_wise_notification,
          :enable_expire_block_flat_details,
          :chart_type,
          :mcube_outbound_number_rotation_enabled,
          :enable_customize_status_report,
          :enable_project_share,
          :enable_sv_form_print,
          :secondary_source_enabled,
          :enable_restricted_fields,
          :enable_deactivate_leads,
          :enable_client_admin_assigning,
          :enable_partner_crm_integration,
          :enable_sv_partner,
          :enable_lead_number,
          :enable_sv_closing_executive_assignment,
          :enable_accounts,
          :enable_gre_partner_access,
          :enable_gre_source_report,
          :enable_inventory_management,
          :nine_nine_update_enabled,
          :set_mobile_10_digit_mandatory,
          :nine_nine_profile_id,
          :enable_push_notify_closing_manager,
          :enable_lead_export,
          :disable_sv_provenance,
          :disable_marketing_roi_executive_access,
          :enable_visit_expiring_card,
          :enable_activity_report_user_logs,
          :enable_activity_report_source_logs,
          :enable_project_brochure,
          :enabled_project_wise_access,
          :enable_advance_mcube,
          :enable_source_wise_sub_source,
          :restrict_duplicate_other_contact_leads,
          :enable_nextel_whatsapp_triggers,
          :enable_user_wise_assign_all_users,
          :enable_mcrm_complete_lead_update,
          :enabled_source_wise_search_access,
          :cp_rm_access_enabled,
          :booking_form_enabled,
          :only_10_digit_mobile_number_enabled,
          :enable_campaign_report,
          :cp_lead_qr_enable,
          :client_visit_qr
        ],
        magic_fields_attributes: [
          :id,
          :name,
          :pretty_name,
          :datatype,
          :is_select_list,
          :is_required,
          :is_sv_required,
          :print_enabled,
          :type_scoped,
          :_destroy,
          :items,
          :is_indexed_field,
          :is_popup_field,
          :fb_form_field,
          :fb_field_name,
          :field_position,
          :section_heading
        ],
        push_notification_setting_attributes: [
          :token,
          :project_key,
          :is_active,
          :id,
          :_destroy
        ],
        mcube_groups_attributes: [
          :id,
          :number,
          :group_name,
          :is_active,
          :_destroy
        ],
        exotel_integration_attributes: [
          :id,
          :title,
          :active,
          :integration_key,
          :token,
          :sid,
          :callback_url
        ],
        mailchimp_integration_attributes: [
          :id,
          :title,
          :active,
          :integration_key,
          :token,
        ],
        mcube_integration_attributes: [
          :id,
          :title,
          :active,
          :integration_key,
          :callback_url
        ],
        sms_integration_attributes: [
          :id,
          :title,
          :active,
          :integration_key,
          :url
        ],
        knowrality_integration_attributes: [
          :id,
          :active,
          :integration_key,
          :token
        ],
        tatatele_integration_attributes: [
          :id,
          :active,
          :integration_key
        ],
        slashrtc_integration_attributes: [
          :id,
          :active,
          :domain,
          :integration_key
        ],
        teleteemtech_integration_attributes: [
          :id,
          :active,
          :token,
          :integration_key
        ],
        callerdesk_integration_attributes: [
          :id,
          :active,
          :integration_key
        ],
        smtp_integration_attributes: [
          :id, :active, :user_name, :token, :domain, :address
        ],
        value_first_integration_attributes: [
          :id, :active, :user_name, :token, :sender
        ],
        whatsapp_integration_attributes: [
          :id,
          :active,
          :user_name,
          :vendor_name,
          :integration_key,
          :token
        ],
        custom_labels_attributes: [
          :id,
          :key,
          :default_value,
          :custom_value,
          :_destroy
        ],
        renewals_attributes: [
          :id,
          :start_date,
          :end_date,
          :customer_success_executive_id,
          :sales_executive_id
        ],
        company_stages_attributes: [
          :id,
          :stage_id,
          :_destroy,
          company_stage_statuses_attributes: [
            :id,
            :status_id,
            :_destroy
          ]
        ]
      )
    end

    def advance_search_params
      params.permit(
        :renewal_from,
        :renewal_upto
      )
    end

    def companies_params
      params.permit(:search_query, :page, :is_advanced_search, :renewal_from, :renewal_upto)
    end
    helper_method :companies_params
end
