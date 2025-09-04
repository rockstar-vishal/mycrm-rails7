class MagicFieldsService
  include MagicFieldsPermittable
  
  attr_reader :company, :lead
  
  def initialize(company, lead = nil)
    @company = company
    @lead = lead
  end
  
  # Create a new lead with magic fields
  def create_lead_with_magic_fields(params_data)
    # Use cached magic fields to avoid performance issues
    magic_field_names = magic_field_names_for_company(@company)
    regular_params = params_data.except(*magic_field_names.map(&:to_s))
    
    # Create lead with regular attributes
    lead = @company.leads.build(regular_params)
    
    # Handle magic fields by creating MagicAttribute records
    magic_field_names.each do |field_name|
      # Convert field_name to string to match params_data keys
      field_name_str = field_name.to_s
      if params_data[field_name_str].present?
        magic_field = @company.magic_fields.find_by(name: field_name_str)
        if magic_field
          lead.magic_attributes.build(magic_field: magic_field, value: params_data[field_name_str])
        end
      end
    end
    
    # Set default values for required fields
    lead.status_id = @company.expected_site_visit_id if lead.tentative_visit_planned.present?
    lead.source_id = ::Source.cp_sources.first.id if lead.source_id.blank?
    
    lead
  end
  
  # Update an existing lead with magic fields
  def update_lead_with_magic_fields(lead, params_data)
    # Use cached magic fields to avoid performance issues
    magic_field_names = magic_field_names_for_company(@company)
    regular_params = params_data.except(*magic_field_names.map(&:to_s))
    
    # Update lead with regular attributes only
    lead.assign_attributes(regular_params)
    
    # Store magic field updates to be applied via callback
    magic_field_updates = {}
    magic_field_names.each do |field_name|
      # Convert field_name to string to match params_data keys
      field_name_str = field_name.to_s
      if params_data[field_name_str].present?
        magic_field = @company.magic_fields.find_by(name: field_name_str)
        if magic_field
          magic_field_updates[field_name] = {
            magic_field: magic_field,
            value: params_data[field_name_str]
          }
        end
      end
    end
    
    # Store the updates to be applied via callback
    lead.instance_variable_set(:@pending_magic_field_updates, magic_field_updates)
    
    lead
  end
  
  # Build lead parameters with magic fields for a specific company
  def build_lead_params_with_magic_fields(additional_params = [])
    # Call the concern method, not self
    super(@company, additional_params)
  end
  
  # Get magic field names for the company
  def get_magic_field_names
    magic_field_names_for_company(@company)
  end
  
  # Check if a field is a magic field
  def magic_field?(field_name)
    @company.magic_fields.exists?(name: field_name.to_s)
  end
  
  # Get magic field value for a lead
  def get_magic_field_value(lead, field_name)
    magic_field = @company.magic_fields.find_by(name: field_name.to_s)
    return nil unless magic_field
    
    magic_attribute = lead.magic_attributes.find_by(magic_field: magic_field)
    magic_attribute&.value
  end
  
  # Set magic field value for a lead
  def set_magic_field_value(lead, field_name, value)
    magic_field = @company.magic_fields.find_by(name: field_name.to_s)
    return false unless magic_field
    
    magic_attribute = lead.magic_attributes.find_or_initialize_by(magic_field: magic_field)
    magic_attribute.value = value
    magic_attribute.save
  end
  
  # Bulk update magic fields for a lead
  def bulk_update_magic_fields(lead, magic_field_values)
    magic_field_values.each do |field_name, value|
      set_magic_field_value(lead, field_name, value)
    end
  end
  
  # Validate magic field values against field constraints
  def validate_magic_field_values(magic_field_values)
    errors = []
    
    magic_field_values.each do |field_name, value|
      magic_field = @company.magic_fields.find_by(name: field_name.to_s)
      next unless magic_field
      
      # Check if field is required
      if magic_field.is_required && value.blank?
        errors << "#{magic_field.pretty_name} is required"
      end
      
      # Check if field is select list and value is valid
      if magic_field.is_select_list && value.present?
        unless magic_field.items.include?(value)
          errors << "#{magic_field.pretty_name} must be one of: #{magic_field.items.join(', ')}"
        end
      end
    end
    
    errors
  end
  
  # Get all magic fields for the company with their current values for a lead
  def get_magic_fields_with_values(lead = nil)
    magic_fields = @company.magic_fields.order(:field_position)
    
    magic_fields.map do |magic_field|
      value = nil
      if lead
        magic_attribute = lead.magic_attributes.find_by(magic_field: magic_field)
        value = magic_attribute&.value
      end
      
      {
        id: magic_field.id,
        name: magic_field.name,
        pretty_name: magic_field.pretty_name,
        datatype: magic_field.datatype,
        is_required: magic_field.is_required,
        is_select_list: magic_field.is_select_list,
        items: magic_field.items,
        default: magic_field.default,
        section_heading: magic_field.section_heading,
        value: value
      }
    end
  end
  
  # Create a lead with magic fields using the service
  def self.create_lead(company, params_data)
    service = new(company)
    lead = service.create_lead_with_magic_fields(params_data)
    lead.save
    lead
  end
  
  # Update a lead with magic fields using the service
  def self.update_lead(company, lead, params_data)
    service = new(company, lead)
    updated_lead = service.update_lead_with_magic_fields(lead, params_data)
    updated_lead.save
    updated_lead
  end
end
