module Api
  module MobileCrm
    class SiteVisitInformationsController < ::Api::MobileCrmController
      include MagicFieldsPermittable
      include Base64ImageHandler
      before_action :authenticate, except: [:settings, :create_lead, :fetch_broker, :create_broker, :fetch_lead, :get_users, :get_cp_ids, :get_executives, :get_projects, :get_sources, :get_sub_sources, :get_brokers, :get_cities, :get_locality, :get_visit_status, :get_brokers_by_firm_name, :get_brokers_firm_name]
      before_action :find_company, :set_api_key, only: [:create_lead, :settings, :fetch_broker, :create_broker, :fetch_lead, :get_users, :get_projects, :get_sources, :get_sub_sources, :get_brokers, :get_cities, :get_executives,  :get_locality, :get_cp_ids, :get_visit_status, :get_brokers_by_firm_name, :get_brokers_firm_name]
      before_action :set_leads, only: [:create_lead, :fetch_lead]

      def create_lead
        email = lead_params[:email] rescue ""
        phone = lead_params[:mobile] rescue ""
        dead_status_ids = @company.dead_status_ids
        if lead_params[:user_id].present?
          user = @company.users.find_by(id: lead_params[:user_id])
        else
          projects_users = @company.users_projects.where(project_id: lead_params[:project_id])
          gre_pu = projects_users.joins(:user).where("users.role_id = ?", (Role.find_by_name("Supervisor").id rescue 7))
          if gre_pu.present?
            user = gre_pu.first.user
          else
            user = projects_users.first.user rescue nil
          end
        end
        closing_executive_user = @company.users.find_by(id: lead_params[:closing_executive])
        status_id=lead_params[:status_id].present? ? lead_params[:status_id] : @company.site_visit_done&.id
        status_id=(lead_params[:status_id].present? && !dead_status_ids.include?(lead_params[:status_id].to_s)) ? lead_params[:status_id] : @company.site_visit_done&.id
        @leads = @leads.where(project_id: lead_params[:project_id]) if lead_params[:project_id].present?
        @lead = @leads.where("((email != '' AND email IS NOT NULL) AND email = ?) OR ((mobile != '' AND mobile IS NOT NULL) AND RIGHT(REPLACE(mobile,' ',''), 10) LIKE ?)", email, "#{phone.strip.last(10) if phone.present?}").last
        @lead = @leads.new unless @lead.present?
        is_new_record = @lead.new_record?
        
        # Get the parameters and separate magic fields from regular attributes
        params_data = lead_params.merge(:status_id=>status_id)
        magic_field_names = magic_field_names_for_company(@company)
        
        # Process image parameter if it's a base64 data URI
        params_data = process_base64_image_param(params_data)
        
        # Handle conflicting fields (fields that are both regular attributes and magic fields)
        conflicting_fields = [:city, :budget] # Add other conflicting fields here if needed
        conflicting_magic_fields = magic_field_names & conflicting_fields
        
        # Filter out magic fields from regular attributes, including conflicting ones
        regular_params = params_data.except(*magic_field_names)
        
        # Remove conflicting fields from regular_params to prevent AssociationTypeMismatch
        conflicting_magic_fields.each do |field|
          regular_params.delete(field)
          Rails.logger.info "Removed conflicting field '#{field}' from regular_params (handled as magic field)"
        end
        
        # Update existing lead with regular attributes
        @lead.assign_attributes(regular_params)
        
        # Handle magic fields by creating/updating MagicAttribute records
        magic_field_names.each do |field_name|
          if params_data[field_name].present?
            magic_field = @company.magic_fields.find_by(name: field_name.to_s)
            if magic_field
              if is_new_record
                @lead.magic_attributes.build(magic_field: magic_field, value: params_data[field_name])
              else
                magic_attribute = @lead.magic_attributes.find_or_initialize_by(magic_field: magic_field)
                magic_attribute.value = params_data[field_name]
              end
            end
          end
        end
        @lead.source_id = @company.sources.first.id if @lead.source_id.blank?
        # @lead.closing_executive = closing_executive_user.id if closing_executive_user.present?
        @lead.closing_executive = @company.enable_meeting_executives && closing_executive_user.present? ? closing_executive_user.id : nil
        @lead.user_id = user.id if user.present?
        # @lead.closing_executive = user.id if @lead.closing_executive.blank? && user.present?
        if params[:end_point].present? && params[:end_point] == "CP" && is_new_record
          @lead.source_id = @company.cp_sources.first.id
          broker_id = fetch_broker_from_partners lead_params[:broker_id]
          @lead.broker_id = broker_id
        end
        if @lead.save
          @visit = create_site_visit
          if params[:end_point].present? && params[:end_point]=="CP"
            if is_new_record
              lead_no = create_partner_lead user, @lead.project
              @lead.update(partner_lead_no: lead_no)
            else
              add_partner_visit @lead
            end
          end
          render json: {status: true, message: "Success", lead: @lead.reload.as_api_response(:meta_details_with_detail), current_visit: @visit.as_api_response(:sv_form_print_format)}, status: 201 and return
        else
          render json: {status: false, message: @lead.errors.full_messages.join(', ')}, status: 422 and return
        end
      end

      # def old_create_lead
      #   email = lead_params[:email] rescue ""
      #   phone = lead_params[:mobile] rescue ""
      #   if params[:end_point].present? && params[:end_point]=="CP"
      #     create_partner_lead
      #   else
      #     dead_status_ids = @company.dead_status_ids
      #     if lead_params[:user_id].present?
      #       user = @company.users.find_by(id: lead_params[:user_id]) rescue nil
      #     else
      #       user=@company.users_projects.find_by_project_id(lead_params[:project_id]).user rescue nil
      #     end
      #     status_id=lead_params[:status_id].present? ? lead_params[:status_id] : @company.site_visit_done&.id
      #     status_id=(lead_params[:status_id].present? && !dead_status_ids.include?(lead_params[:status_id].to_s)) ? lead_params[:status_id] : @company.site_visit_done&.id
      #     @leads = @leads.where(project_id: lead_params[:project_id]) if lead_params[:project_id].present?
      #     @lead = @leads.where("((email != '' AND email IS NOT NULL) AND email = ?) OR ((mobile != '' AND mobile IS NOT NULL) AND RIGHT(REPLACE(mobile,' ',''), 10) LIKE ?)", email, "#{phone.strip.last(10) if phone.present?}").last
      #     if @lead.present? && !@company.restrict_sv_form_duplicate_lead_visit
      #       gre_user=@company.enable_sv_closing_executive_assignment ? (@company.users_projects.find_by_project_id(lead_params[:project_id]).user.id rescue nil) : (lead_params[:closing_executive].present? ? lead_params[:closing_executive] : @lead.closing_executive)
      #       if @lead.update(lead_params.merge(:status_id=>status_id, closing_executive: gre_user))
      #         @visit = create_site_visit
      #         if @company.setting.present? && @company.enable_gre_partner_access
      #           inactive_partner_lead
      #         end
      #         render json: {status: true, message: "Updated", lead: @lead.reload.as_api_response(:meta_details_with_detail), current_visit: @visit.as_api_response(:sv_form_print_format)}, status: 201 and return
      #       else
      #         render json: {status: false, message: @lead.errors.full_messages.join(', ')}, status: 422 and return
      #       end
      #     else
      #       @lead = @leads.new
      #       @lead.assign_attributes(lead_params.merge(:status_id => status_id, user_id: user&.id))
      #       if @lead.save
      #         @visit = create_site_visit
      #         if @company.setting.present? && @company.enable_gre_partner_access
      #           inactive_partner_lead
      #         end
      #         render json: {status: true, message: "Success", lead: @lead.as_api_response(:meta_details_with_detail), current_visit: @visit.as_api_response(:sv_form_print_format)}, status: 201 and return
      #       else
      #         render json: {status: false, message: @lead.errors.full_messages.join(', ')}, status: 422 and return
      #       end
      #     end
      #   end
      # end

      def create_broker
        @broker = @company.brokers.new(broker_params)
        if @broker.save
          render json: {status: true, broker: @broker.as_json(only: [:id, :name, :rera_number, :firm_name, :mobile, :locality, :email])}, status: 201 and return
        else
          render json: {status: false, message: @broker.errors.full_messages.join(', ')}, status: 422 and return
        end
      end

      def settings
        projects = @company.projects.active.select("projects.id, projects.name as text").as_json
        sources = @company.sources.reorder(nil).order(:name).select("sources.id, sources.name as text").as_json
        cp_sources = @company.cp_sources&.ids rescue nil
        digital_sources_ids =  @company.digital_sources&.ids rescue nil
        reference_source_ids = @company.referal_sources&.ids rescue nil
        digital_sub_souces = SubSource.where(name: Lead::DIGITALSUBSOURCES).select("id, name as text").as_json
        sub_sources = @company.sub_sources.select("id, name as text").as_json
        brokers = @company.brokers.select("brokers.id, CONCAT ( (CONCAT (brokers.name, '--', brokers.firm_name)), '--', brokers.cp_code) as text, brokers.mobile as contact_number, brokers.rera_number, brokers.locality, brokers.firm_name, brokers.name, brokers.email").as_json
        users=@company.users.select("users.id, users.name as text").as_json
        closing_executives = @company.users.meeting_executives.select("users.id, users.name as text").as_json
        cities=::City.all.select("cities.id, cities.name as text").as_json
        localities=::Locality.includes(region: [:city]).as_api_response(:details)
        statuses=@company.statuses.where(id: [@company.hot_status_ids.reject(&:blank?), @company.dead_status_ids.reject(&:blank?)].flatten).select("statuses.id, statuses.name as text").as_json
        other_source=@company.sources.find_by(name: "Other")&.id
        render json: {projects: projects, brokers: brokers, sources: sources, cp_sources_ids: cp_sources, reference_source_ids: reference_source_ids, digital_sources_ids: digital_sources_ids, users: users, closing_executives: closing_executives, cities: cities, localities: localities, digital_sub_souces: digital_sub_souces, sub_sources: sub_sources, statuses: statuses, other_source: other_source}, status: 200 and return
      end

      def fetch_broker
        render json: {message: "Require Broker id"}, status: 400 and return if params[:broker_id].blank?
        broker = Broker.find(params[:broker_id])
        details = {firm_name: broker.firm_name, rera_no: broker.rera_number, mobile_no: broker.mobile, cp_code: broker.cp_code}
        render json: details, status: 200 and return
      end


      def fetch_lead
        phone = params[:mobile].presence
        lead_no = params[:lead_no].presence
        project_id = params[:project_id]
        is_cp_endpoint = params[:end_point].to_s == "CP"

        @lead = nil

        if lead_no.present? || phone.present?
          if is_cp_endpoint
            @lead = @leads.where(partner_lead_no: lead_no).last if lead_no.present?
            if @lead.nil?
              es = ExternalService.new(@company, { "phone" => phone, "lead_no" => lead_no })
              details = es&.fetch_partner_lead
              @lead = JSON.parse(details) if details.present?
              if @lead["lead"].present?
                @lead["lead"]["project_id"] = @company.projects.find_by(name: @lead.dig("lead", "project")).id rescue nil
                @lead["lead"]['user_id'] = nil
                broker = @company.brokers.find_by(name: @lead.dig("lead", "broker_detail", "name"))
                @lead['lead']['broker_detail'] = {
                  "id" => broker&.id,
                  "name" => broker&.name,
                  "phone" => broker&.mobile,
                  "firm_name" => broker&.firm_name,
                  "email" => broker&.email,
                  "rera_no" => broker&.rera_number,
                  "cp_code" => broker&.cp_code
                }
              end
            end
          else
            @lead = @leads.where(lead_no: lead_no).last if lead_no.present?
            if phone.present?
              cleaned_phone = phone.strip.last(10)
              @lead ||= @leads
                          .where(project_id: project_id)
                          .where("((mobile != '' AND mobile IS NOT NULL) AND RIGHT(REPLACE(mobile, ' ',''), 10) LIKE ?)", cleaned_phone)
                          .last
            end
          end
        end
        project = if @lead.is_a?(Hash)
                    @company.projects.find_by(name: @lead.dig("lead", "project")) || @company.projects.find_by(id: project_id)
                  else
                    @lead&.project || @company.projects.find_by(id: project_id)
                  end

        form_no = nil
        if @company.magic_fields&.pluck(:name)&.include?("form_no")
          form_values = project.leads
                               .joins(magic_attributes: :magic_field)
                               .where(magic_fields: { name: "form_no" })
                               .pluck("magic_attributes.value")
                               .map(&:to_i)
          form_no = form_values.max || 0
        end

        if @lead.present?
          if @lead.is_a?(Hash)
            render json: { lead: @lead["lead"], form_no: form_no }, status: 200 and return
          end

          structure = @company.structures.find_by(domain: params[:domain])
          if structure&.break_name_field
            name_parts = @lead.name.to_s.split
            salutation = name_parts.first.to_s
            last_name = name_parts.last.to_s
            first_name = (name_parts[1..-2] || []).join(" ")
            lead_data = @lead.as_api_response(:meta_details_with_detail).merge(
              salutation: salutation,
              last_name: last_name,
              first_name: first_name
            )
            render json: { lead: lead_data, form_no: form_no }, status: 200 and return
          else
            render json: { lead: @lead.as_api_response(:meta_details_with_detail), form_no: form_no }, status: 200 and return
          end
        else
          render json: { message: "Lead is not present", form_no: form_no }, status: 200 and return
        end
      end


      def get_projects
        es = ExternalService.new(@company)
        if params[:end_point].present? && params[:end_point]=="CP"
          details=es.fetch_partners_projects
          if details.present?
            projects = JSON.parse(details)
          end
        else
          projects = @company.projects.select("projects.id, name, sv_form_budget_options").map{|k| {id: k.id, text: k.name, sv_form_budget_options: (k.sv_form_budget_options.present? ? k.sv_form_budget_options.split(", ") : nil)}}
        end
        render json: projects, status: 200 and return
      end

      def get_sources
        es = ExternalService.new(@company)
        if params[:end_point].present? && params[:end_point]=="CP"
          details=es.get_partner_sources
          if details.present?
            sources = JSON.parse(details)
          end
        else
          sources=@company.sources.select("sources.id, name as text").as_json
        end
        render json: sources, status: 200 and return
      end

      def get_sub_sources
        sources=@company.sub_sources.select("sub_sources.id, sub_sources.name as text").as_json
        render json: sources, status: 200 and return
      end

      def get_brokers
        es = ExternalService.new(@company)
        if params[:end_point].present? && params[:end_point]=="CP"
          details=es.get_partners
          if details.present?
            brokers = JSON.parse(details)
          end
        else
          brokers=@company.brokers.select("brokers.id, CONCAT(brokers.name, '--', brokers.firm_name) as text").as_json
        end
        render json: brokers, status: 200 and return
      end

      def get_brokers_firm_name
        if params[:search_string].present?
          brokers = @company.brokers
                      .where("firm_name ILIKE ?", "%#{params[:search_string]}%")
                      .where.not(firm_name: [nil, ''])
                      .order(id: :desc) # Order by ID in descending order
                      .pluck(:id, "lower(firm_name) AS text")
                      .group_by { |_, text| text } # Group by lowercase firm name
                      .map { |text, broker_data| { id: broker_data.first.first, text: text.upcase } }
                      .sort_by { |broker| broker[:text] }
          render json: brokers, status: 200 and return
        else
          render json: { error: "Broker firm name required" }, status: 422
        end
      end

      def get_brokers_by_firm_name
        if params[:firm_name].present?
          brokers = @company.brokers.where("TRIM(LOWER(firm_name)) = ?", params[:firm_name].strip.downcase).select("brokers.id, brokers.name AS text").as_json
          render json: brokers, status: 200 and return
        else
          render json: { error: "Firm name required" }, status: 422
        end
      end

      def get_users
        es = ExternalService.new(@company)
        if params[:end_point].present? && params[:end_point]=="CP"
          details=es.get_partner_users
          if details.present?
            users = JSON.parse(details)
          end
        else
          if params[:project_id].present?
            project=Project.find_by(id: params[:project_id])
            users=@company.users.where(id: project.accessible_users.ids).select("users.id, users.name as text").as_json
          else
            users=@company.users.select("users.id, users.name as text").as_json
          end
        end
        render json: users, status: 200 and return
      end

      def get_executives
        if params[:end_point].present? && params[:end_point]=="CP"
          es = ExternalService.new(@company)
          details=es.get_partner_users
          if details.present?
            executives = JSON.parse(details)
          end
        else
          if params[:project_id].present?
            project=Project.find_by(id: params[:project_id])
            executives = @company.users.where(id: project.accessible_users.ids).meeting_executives.select("users.id, users.name as text").as_json
          else
            executives = @company.users.meeting_executives.select("users.id, users.name as text").as_json
          end
        end
        render json: executives, status: 200 and return
      end

      def get_visit_status
        visit_statuses=Leads::Visit.status_ids.keys
        mapped_array = visit_statuses.map { |item| { id: item, text: item } }
        json_data = mapped_array.to_json
        render json: json_data, status: 200 and return
      end

      def get_cities
        cities=::City.all.select("cities.id, cities.name as text").as_json
        render json: cities, status: 200 and return
      end

      def get_locality
        if params[:end_point].present? && params[:end_point]=="CP"
          es = ExternalService.new(@company)
          details=es.get_localities
          if details.present?
            localities = JSON.parse(details)
          end
        else
          localities=::Locality.all.select("localities.id, localities.name as text").as_json
        end
        render json: localities, status: 200 and return
      end

      def add_partner_visit lead
        email = lead.postsale_user.email rescue nil
        lead_no = lead.partner_lead_no
        es = ExternalService.new(@company, {lead_no: lead_no, closing_exec_email: email})
        es.create_partner_visit
      end

      def create_partner_lead user, project
        es = ExternalService.new(@company)
        details=es.fetch_partners_projects
        if details.present?
          partners_projects = JSON.parse(details)
          partner_project_id = partners_projects.detect{|k| k["text"] == project.name}["id"] rescue nil
          lead_request_params = lead_params
          lead_request_params["project_id"] = partner_project_id if partner_project_id.present?
          request_dat = {email: (user.email rescue ""), lead_params: lead_request_params}
          begin
            es = ExternalService.new(@company, request_dat)
            req = es.partner_params_formation
            es = ExternalService.new(@company, req)
            data = es.create_partners_lead
            if data.present?
              res_data = JSON.parse data
              return res_data["data"]["lead_no"]
            else
              return nil
            end
          rescue => e
            puts e.message
          end
        else
          Rails.logger.info("--------------------- Partner Projects not found for company - #{company.id}. Partner Lead not Created!! ---------------")
        end
      end

      def get_cp_ids
        request={}
        es = ExternalService.new(@company, request)
        es.get_cp_ids
      end

      private


      def inactive_partner_lead
        request = {"phone" => @lead.mobile.last(10), "project_name"=>@lead.project.name, "lead_no"=>@lead.lead_no}
        es = ExternalService.new(@company, request)
        details=es.inactive_partner_lead
      end

      def fetch_broker_from_partners broker_id
        es = ExternalService.new(@company)
        details = es.fetch_partners_broker broker_id
        broker_json = JSON.parse details
        broker = @company.brokers.where("RIGHT(replace(mobile, ' ', ''), 10) LIKE ?", broker_json["phone"].last(10)).first
        if broker.blank?
          broker = @company.brokers.create(name: broker_json["name"], firm_name: broker_json["firm_name"], mobile: broker_json["phone"])
        end
        return broker.reload.id
      end

      def create_site_visit
        prev_presale_id = (@company.users.calling_executives.find_by(id: params[:lead][:visit_user_id])&.id rescue nil)
        status_id=params[:lead][:lead_visit_status_id]
        visit = @lead.visits.create(
          date: Time.zone.now,
          user_id: prev_presale_id,
          status_id: status_id
        )
        return visit
      end

      def find_company
        @company = (::Company.find_by_uuid params[:uuid]) rescue nil
        render json: {message: "Invalid Company ID"}, status: 400 and return if @company.blank?
      end

      def set_leads
        @leads = @company.leads.active_for(@company)
      end

      def set_api_key
        find_api_obj || render_invalid
      end

      def render_invalid
        render json: {message: 'Invalid API Key'}, status: 401 and return
      end

      def find_api_obj
        authenticate_with_http_token do |token, options|
          @api_obj = @company.api_keys.find_by_key token
          return true if @api_obj.present?
          return false
        end
      end

      def lead_params
        standard_lead_params(@company, [:closing_executive, :budget, :enable_admin_assign, :enquiry_sub_source_id, :ncd, :other_emails, :other_phones, :signature, :source_id, :broker_id, :user_id, :image, :referal_name, :referal_mobile, :presale_user_id, :status_id, :lead_visit_status_id])
      end

      def broker_params
        params.require(:broker).permit(:name, :email, :mobile, :firm_name, :locality, :rera_number, :rm_id, :other_contacts, :cp_code)
      end

    end
  end
end
