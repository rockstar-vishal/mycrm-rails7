module Api
  module MobileCrm
    class SiteVisitConfigurationsController < ::Api::MobileCrmController
      before_action :authenticate, except: [:settings]
      before_action :find_company, only: [:settings]

      def settings
        logo_url = @sv_form.sv_logo.present? ? @sv_form.sv_logo.url : @company.logo.url
        projects = @company.projects.select("projects.id, name, sv_form_budget_options").map{|k| {id: k.id, text: k.name, sv_form_budget_options: (k.sv_form_budget_options.present? ? k.sv_form_budget_options.split(", ") : nil)}}
        sources = @company.sources.select("sources.id, name as text").as_json
        sourcing_manager_show = @company.magic_fields&.pluck(:name)&.include?("sourcing_manager")
        if @company.magic_fields&.pluck(:name)&.include?("sourcing_manager")
          @sourcing_manager_field = @company.magic_fields.find_by(name: "sourcing_manager")
          sourcing_manager = @sourcing_manager_field&.items || []
        else
          sourcing_manager = []
        end
        company_details={id: @company.uuid, token: @company.api_keys.first.key, title: @sv_form.title, sv_domain: @sv_form.domain, logo_url: logo_url, signature: (@sv_form.structure_fields.pluck(:name).include? "signature"), image: (@sv_form.structure_fields.pluck(:name).include? "image_file_name"), cp_sources: (@company.cp_sources&.ids rescue nil), referal_sources: (@company.referal_sources&.ids rescue nil), print_sv_form: @company.enable_sv_form_print, is_sv_partner_enable: @company.setting.present? && @company.enable_sv_partner, is_otp_enable: @sv_form.enable_otp, is_provenance_disabled: @company.setting.present? && @company.disable_sv_provenance, closing_executive: (@sv_form.structure_fields.pluck(:name).include? "closing_executive"), user_wise_project_enable: @company.setting.present? && @company.enabled_project_wise_access, disabled_sv_fields: @sv_form.disabled_sv_fields.reject(&:blank?), bg_color: @sv_form.bg_color, primary_color: @sv_form.primary_color, dark_color_fix: @sv_form.dark_color_fix, enable_admin_assign: (@company.setting.present? && @company.enable_client_admin_assigning), seperate_firm_name_broker_name: @sv_form.seperate_firm_name_broker_name, hide_image_upload_option: @sv_form.hide_image_upload_option, break_name_field: @sv_form.break_name_field, projects: projects, sources: sources, ten_digit_mobile_number_enabled: @company.setting.present? && @company.only_10_digit_mobile_number_enabled, sourcing_manager: sourcing_manager, sourcing_manager_show: sourcing_manager_show }
        site_fields = StructureField.get_fields(@sv_form) rescue nil
        if site_fields.present?
          grouped_fields = site_fields.group_by { |field| field["heading"] }
          sv_field = grouped_fields.map do |heading, fields|
            {
              heading: heading,
              data: fields.flat_map do |field|
                if @sv_form.break_name_field && field.name == "name"
                  [
                    {
                    id: "#{field['id']}.1",
                    name: "salutation",
                    label: "Salutation",
                    is_select_list: true,
                    required: field["required"],
                    datatype: "string",
                    position: field["field_position"],
                    created_at: field["created_at"],
                    enpoint_url: nil,
                    items: ["Mr.","Mrs.","Ms.","Dr.","Col.","Adv."]
                  },
                  {
                    id: "#{field['id']}.2",
                    name: "first_name",
                    label: "First Name",
                    is_select_list: false,
                    required: field["required"],
                    datatype: "string",
                    position: field["field_position"],
                    created_at: field["created_at"],
                    enpoint_url: StructureField.get_endpoints(@company, field["name"]),
                    items: field["items"]
                  },
                  {
                    id: "#{field['id']}.3",
                    name: "last_name",
                    label: "Last Name",
                    is_select_list: false,
                    required: field["required"],
                    datatype: "string",
                    position: field["field_position"],
                    created_at: field["created_at"],
                    enpoint_url: StructureField.get_endpoints(@company, field["name"]),
                    items: field["items"]
                  }
                ]
                else
                  {
                    id: field["id"],
                    name: field["name"],
                    label: field["label"],
                    is_select_list: field["is_select_list"],
                    required: field["required"],
                    datatype: field["datatype"],
                    position: field["field_position"],
                    created_at: field["created_at"],
                    enpoint_url: StructureField.get_endpoints(@company, field["name"]),
                    items: field["items"]
                  }
                end
              end
            }
          end
        else
          sv_field = []
        end
        render json: {company_details: company_details, sv_field: sv_field}, status: 200 and return
      end

      private

      def find_company
        render json: {message: "SV Domain C'ant be blank"}, status: 400 and return unless params[:sv_domain].present?
        @sv_form = ::Structure.for_sv.find_by(domain: params[:sv_domain])
        render json: {message: "Invalid Domain"}, status: 400 and return unless @sv_form.present?
        @company= @sv_form.company
      end
    end
  end
end
