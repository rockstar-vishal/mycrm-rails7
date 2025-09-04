module MagicFieldsPermittable
  extend ActiveSupport::Concern

  # Helper method to get magic field names for a company
  def magic_field_names_for_company(company)
    # Use cached magic fields to avoid performance issues
    Rails.cache.fetch("magic_fields_#{company.id}", expires_in: 1.hour) do
      company.magic_fields.pluck(:name).map(&:to_sym) rescue []
    end
  end

  # Invalidate magic fields cache for a company
  def invalidate_magic_fields_cache(company)
    Rails.cache.delete("magic_fields_#{company.id}")
  end

  # Helper method to build permitted parameters including magic fields
  def build_lead_params_with_magic_fields(company, additional_params = [])
    magic_fields = magic_field_names_for_company(company)
    Rails.logger.info "Magic fields for company #{company.id}: #{magic_fields.inspect}"
    
    base_params = [
      :date, :name, :email, :mobile, :other_phones, :other_emails, :address,
      :is_qualified, :city, :state, :country, :budget, :source_id, :sub_source,
      :broker_id, :project_id, :user_id, :closing_executive, :ncd, :comment,
      :status_id, :lead_no, :call_in_id, :dead_reason_id, :dead_sub_reason,
      :city_id, :locality_id, :tentative_visit_planned, :enable_admin_assign,
      :property_type, :is_deactivated, :stage, :referal_name, :referal_mobile,
      :presale_stage_id, :booking_date, :booking_form, :token_date,
      :bank_person_name, :bank_person_contact, :bank_sales_person,
      :booked_flat_no, :bank_loan_name, :enquiry_sub_source_id,
      :customer_type, :lease_expiry_date, :project_uuid, :unit, :pickup_address,
      :uuid
    ]
    
    # Add magic fields and additional params
    all_params = base_params + magic_fields + additional_params
    
    # Add nested attributes if needed
    nested_attrs = {
      secondary_source_ids: [],
      visits_attributes: [:id, :date, :status_id, :source_id, :is_visit_executed, 
                        :is_postponed, :is_canceled, :comment, :site_visit_form, 
                        :location, :surronding, :finalization_period, :loan_sanctioned, 
                        :bank_name, :loan_amount, :eligibility, :own_contribution_minimum, 
                        :own_contribution_maximum, :loan_requirements, :_destroy, 
                        project_ids: []],
      residential_type_attributes: [:id, :property_type, :purpose, :plot_area_from, 
                                  :plot_area_to, :area_config, :area_unit],
      commercial_type_attributes: [:id, :property_type, :area_unit, :plot_area_from, 
                                  :plot_area_to, :is_attached_toilet, :purpose_comment, :purpose]
    }
    
    all_params + [nested_attrs]
  end

  # Standard lead_params method that can be used across controllers
  def standard_lead_params(company, additional_params = [])
    permitted_params = build_lead_params_with_magic_fields(company, additional_params)
    Rails.logger.info "Final permitted params: #{permitted_params.inspect}"
    params.require(:lead).permit(*permitted_params)
  end

  # Search params with magic fields
  def search_params_with_magic_fields(company)
    magic_fields = magic_field_names_for_company(company)
    base_search_params = [
      :name, :visited, :visit_expiring, :backlogs_only, :todays_call_only,
      :visit_form, :merged, :ncd_from, :exact_ncd_upto, :exact_ncd_from,
      :created_at_from, :updated_at_from, :updated_at_upto, :expired_from,
      :expired_upto, :created_at_upto, :visited_date_from, :booking_date_from,
      :booking_date_to, :token_date_to, :token_date_from, :visited_date_upto,
      :ncd_upto, :agreement_date_from, :agreement_date_upto,
      :booking_cancelled_date_from, :booking_cancelled_date_upto, :email,
      :state, :mobile, :other_phones, :comment, :lead_no, :manager_id,
      :budget_from, :site_visit_done, :site_visit_planned, :revisit,
      :booked_leads, :token_leads, :visit_cancel, :postponed, :budget_upto,
      :visit_counts, :visit_counts_num, :sub_source, :customer_type,
      :deactivated, :site_visit_from, :site_visit_upto, :reinquired_from,
      :reinquired_upto, :is_qualified, :source_id,
      # Additional search parameters used in mobile CRM and other controllers
      :as, :bs, :ss_id, :key, :sort, :page, :per_page, :display_from,
      :start_date, :end_date, :call_direction, :first_call_attempt,
      :lead_name, :call_from, :call_to, :missed_calls, :past_calls_only,
      :todays_calls, :completed, :abandoned_calls, :updated_from, :updated_upto,
      :incoming, :site_visit_cancel,
      # Additional parameters from call logs and other search methods
      :search_query, :is_advanced_search, :search_string, :calender_view,
      :visit_status_ids, :renewal_from, :renewal_upto
    ]
    
    array_params = [
      :dead_reason_ids, :project_ids, :assigned_to, :lead_statuses,
      :city_ids, :locality_ids, :source_id, :lead_stages, :presale_user_id,
      :sub_source_ids, :lead_ids, :broker_ids, :country_ids,
      :closing_executive, :dead_reasons, :sv_user, :manager_ids,
      # Additional array parameters
      :source_ids, :user_ids, :call_status, :abandoned_calls_status,
      :role_ids, :lead_statuses, :project_ids, :broker_ids
    ]
    
    all_params = base_search_params + magic_fields + array_params
    params.permit(*all_params)
  end
end
