class StructureField < ActiveRecord::Base
  include StructureFieldExtension
  
  belongs_to :structure
  before_save :check_lead_field
  default_scope { order(created_at: :asc) }

  def check_lead_field
    if ::Company.sv_allowed_options.include? self.name
      self.datatype = (["other_phones", "other_emails"].include? self.name) ? "string" : (["lead_visit_status_id"].include? self.name) ? "integer" :  (["image_file_name"].include? self.name) ? "image" :  Lead.columns_hash["#{self.name}"].type.to_s
      self.is_select_list = true if ::Company.lead_select_fields.include? self.name
    end
  end


  class << self
    def get_fields(sv_form)
      query = <<-SQL
        SELECT id as id, name as name, section_heading as heading, label as label, datatype as datatype, is_select_list, items as items, 
               is_required as required, print_enabled as print_enabled, created_at as created_at, field_position as field_position
        FROM structure_fields
        WHERE structure_id = ?
        UNION ALL
        SELECT magic_fields.id, magic_fields.name as name, magic_fields.section_heading as heading, pretty_name as label, datatype as datatype, 
               is_select_list, items as items,
               CASE WHEN is_sv_required IS NOT NULL THEN is_sv_required ELSE is_required END as required, magic_fields.print_enabled as print_enabled, 
               magic_fields.created_at as created_at, field_position as field_position
        FROM magic_fields
        INNER JOIN magic_field_relationships ON magic_field_relationships.magic_field_id = magic_fields.id
        WHERE magic_field_relationships.owner_id = ?
          AND magic_fields.section_heading IS NOT NULL
          AND magic_fields.section_heading != ''
        ORDER BY field_position
      SQL
      query = ActiveRecord::Base.send(:sanitize_sql_array, [query, sv_form.id, sv_form.company.id])
      StructureField.find_by_sql(query) rescue nil
    end

    def get_endpoints(company, name)
      if name=="project_id"
        endpoint = "companies/#{company.uuid}/get_projects"
      elsif name == "broker_id"
        endpoint = "companies/#{company.uuid}/get_brokers"
      elsif name == "source_id"
        endpoint = "companies/#{company.uuid}/get_sources"
      elsif name == "enquiry_sub_source_id"
        endpoint = "companies/#{company.uuid}/get_sub_sources"
      elsif name == "user_id"
        endpoint = "companies/#{company.uuid}/get_users"
      elsif name =="closing_executive"
        endpoint="companies/#{company.uuid}/get_executives"
      elsif name == "city_id"
        endpoint = "companies/#{company.uuid}/get_cities"
      elsif name == "lead_visit_status_id"
        endpoint = "companies/#{company.uuid}/get_visit_status"
      elsif name == "locality_id"
        endpoint = "companies/#{company.uuid}/get_locality"
      end
      return (endpoint rescue nil)
    end
  end

end
