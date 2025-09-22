module Api
  module MobileCrm
    class LeadsController < ::Api::MobileCrmController
      include MagicFieldsPermittable
      include Base64ImageHandler

      before_action :find_accessible_leads

      before_action :find_lead, only: [:show, :update, :delete_visit, :log_call_attempt, :log_call_attempt, :make_call, :histories, :deactivate]
      before_action :create_call_attempt, only: :make_call
      PER_PAGE = 20

      def index
        @leads = @leads.includes(:status, :source, :project, :postsale_user, leads_secondary_sources: :source)

        if params[:bs].present?
          @leads = @leads.basic_search(params[:bs], @current_app_user)
        end
        if params[:as].present?
          if params[:ss_id].present?
            ss = @current_app_user.search_histories.find(params[:ss_id])
            @leads = @leads.advance_search(ss.search_params, @current_app_user)
          else
            @leads = @leads.advance_search(search_params, @current_app_user)
          end
        end
        if params[:bs].blank? && params[:as].blank?
          @leads = @leads.active_for(@current_app_user.company)
        end
        if params["key"].present? && params["sort"].present?
          sort_key = params['key']
          sort_order = current_user.company.setting.present? && current_user.company.enable_ncd_sort_nulls_last && params['sort'] == "desc" ? "DESC NULLS LAST" : "ASC NULLS FIRST"
          @leads = @leads.order("#{sort_key} #{sort_order}")
        else
          @leads = @leads.order("leads.ncd asc NULLS FIRST, leads.created_at DESC")
        end
        total_leads = @leads.size
        leads = @leads.paginate(:page => params[:page], :per_page => PER_PAGE).as_api_response(:details)
        render json: {leads: leads, count: total_leads, per_page: PER_PAGE}, status: 200 and return
      end

      def show
        hide_lead_mobile_for_executive = current_user.is_executive? && current_user.company.setting&.hide_lead_mobile_for_executive
        render json: { status: true, lead: @lead.as_api_response(:meta_details_with_detail).merge(hide_lead_mobile_for_executive: hide_lead_mobile_for_executive) }, status: 200 and return
      end

      def create
        lead = @leads.new
        
        # Process image parameter if it's a base64 data URI
        params_data = process_base64_image_param(lead_params)
        
        lead.assign_attributes(params_data)
        lead.user_id = @current_app_user.id if lead.user_id.blank?
        if lead.save
          render json: {status: true, message: "Success"}, status: 201 and return
        else
          render json: {status: false, message: lead.errors.full_messages.join(', ')}, status: 422 and return
        end

      end

      def settings
        if current_user.company.can_assign_all_users || current_user.assign_all_users_permission
          users = current_user.company.users.active
        else
          users = current_user.manageables
        end
        users = users.as_json(only: [:id, :name])
        executive_users = current_user.company.can_assign_all_users ? current_user.company.users.active : current_user.company.users.active.where(:id=>current_user.manageable_ids)
        if current_user.company.managerwise_closing_executive_active
          if current_user.is_executive?
            closing_executives = current_user.company.users.managers_role.meeting_executives.select("users.id, users.name").as_json
          else
            closing_executives = executive_users.meeting_executives.select("users.id, users.name").as_json
          end
        else
          closing_executives = executive_users.meeting_executives.select("users.id, users.name").as_json
        end
        projects = current_user.company.projects.as_json(only: [:id, :name])
        bank_names = ::Leads::Visit::BANK_NAMES.as_json
        reference_source_ids = @current_app_user.company.referal_sources&.ids rescue nil
        cities=::City.all.select("cities.id, cities.name as name").as_json
        localities=::Locality.includes(region: [:city]).as_api_response(:details)
        all_localities=::Locality.all.select("id, name").as_json
        visit_status=Leads::Visit.status_ids.keys
        render json: {users: users, projects: projects, bank_names: bank_names, closing_executives: closing_executives, reference_source_ids: reference_source_ids, cities: cities, localities: localities,visit_status: visit_status, all_localities: all_localities}, status: 200 and return
      end

      def histories
        lead_logs = @lead.custom_audits.order(created_at: :desc)
        render json: {audits: lead_logs.as_api_response(:public)}, status: 200 and return
      end

      def magic_fields
        @company = @current_app_user.company
        magic_fields = @company.magic_fields
        render json: { status: true, magic_fields:  magic_fields}, status: 200 and return
      end

      def delete_visit
        visit = @lead.visits.find_by_id(params[:visit_id])
        if visit.destroy
          render json: {message: "Success"}, status: 200 and return
        else
          render json: {message: visit.errors.full_messages.join(', ')}, status: 200 and return
        end
      end

      def update
        if @lead.update(lead_params)
          render json: {lead: @lead.reload.as_api_response(:meta_details_with_detail)}, status: 200 and return
        else
          render json: {status: false, message: @lead.errors.full_messages.join(",")}, status: 400 and return
        end
      end

      def make_call
        if @lead.make_call(@current_app_user)
          render json: {success: true}, status: 200
        else
          render json: {success: false}, status: 200
        end
      end

      def create_call_attempt
        @lead.call_attempts.create(user_id: @current_app_user.id)
      end

      def log_call_attempt
        call_attempt = @lead.call_attempts.build(user_id: @current_app_user.id)
        if call_attempt.save
          render json: {status: true, message: "Success"}, status: 201 and return
        else
          render json: {status: false, message: call_attempt.errors.full_messages.join(', ')}, status: 422 and return
        end
      end

      def deactivate
        @lead.deactivate
        render json: {status: true, message: "Lead deactivated"}, status: 200 and return
      end

      private

      def find_accessible_leads
        @leads = ::Lead.search_base_leads(@current_app_user)
        Lead.current_user = @current_app_user
      end

      def find_lead
        @lead = @leads.find_by_uuid params[:uuid]
        render json: {message: "Cannot find lead", error: "Invalid UUID Sent"}, status: 422 and return if @lead.blank?
      end

      def lead_params
        standard_lead_params(@current_app_user.company)
      end

      def current_user
        @current_app_user
      end

      def search_params
        search_params_with_magic_fields(@current_app_user.company)
      end

    end
  end
end