class Internal::BrokersController < InternalController
  include MagicFieldsPermittable

  def create_broker
    company=Company.find_by(uuid: params[:uuid])
    @broker = company.brokers.new(broker_params)
    if @broker.save
      render json: { success: true}, status: 200 and return
    else
      render json: {status: false, message: "#{@broker.errors.full_messages.join(', ')}"}, status: 422 and return
    end
  end

  def create_lead
    @company=Company.find_by(uuid: params[:uuid])
    @project_id=@company.projects.find_by(name: params["project"])&.id
    @source_id=@company.sources.find_by(name: params["source"])&.id
    @closing_user_id=@company.users.find_by(email: params["closing_user"])&.id
    @user_id=@company.users.find_by(email: params["user"])&.id
    @broker_id = @company.brokers.find_by(mobile: params["broker"])&.id
    @custom_attribute={}
    if params["custom_params"].present?
      @custom_attribute=params["custom_params"].select{|k, v| @company.magic_fields.pluck(:name).include? k}
    end
    leads = @company.leads.where(project_id: @project_id, broker_id: @broker_id).where.not(status_id: @company.dead_status_ids).where("((email != '' AND email IS NOT NULL) AND email = ?) OR ((mobile != '' AND mobile IS NOT NULL) AND RIGHT(mobile, 10) ILIKE ?)", params["email"], "#{params["mobile"].last(10) if params["mobile"].present?}")
    
    # Get the parameters and separate magic fields from regular attributes
    params_data = lead_params(params)
    magic_field_names = magic_field_names_for_company(@company)
    
    # Filter out magic fields from regular attributes
    regular_params = params_data.except(*magic_field_names)
    
    if leads.present?
      @lead=leads.last
      @lead.assign_attributes(regular_params)
      
      # Handle magic fields by updating MagicAttribute records
      magic_field_names.each do |field_name|
        if params_data[field_name].present?
          magic_field = @company.magic_fields.find_by(name: field_name.to_s)
          if magic_field
            magic_attribute = @lead.magic_attributes.find_or_initialize_by(magic_field: magic_field)
            magic_attribute.value = params_data[field_name]
          end
        end
      end
    else
      @lead=@company.leads.new()
      @lead.assign_attributes(regular_params)
      
      # Handle magic fields by creating MagicAttribute records
      magic_field_names.each do |field_name|
        if params_data[field_name].present?
          magic_field = @company.magic_fields.find_by(name: field_name.to_s)
          if magic_field
            @lead.magic_attributes.build(magic_field: magic_field, value: params_data[field_name])
          end
        end
      end
    end
    
    if @lead.save
      if params["visit_params"].present?
        if @lead.visits.any?
          latest_visit_time = @lead.visits.maximum(:created_at)
          latest_partner_visits = params["visit_params"].select { |visit| visit[:created_at] > latest_visit_time }
          if latest_partner_visits.present?
            latest_partner_visits.each do |v|
              @lead.visits.create(date: v["date"],comment: v["comment"])
            end
          end
        else
          params["visit_params"].each do |v|
            @lead.visits.create(date: v["date"],comment: v["comment"])
          end
        end
      end
      render json: { success: true}, status: 200 and return
    else
      render json: {status: false, message: "#{@lead.errors.full_messages.join(', ')}"}, status: 422 and return
    end
  end

  def set_lead_inactive
    company=Company.find_by(uuid: params[:uuid])
    lead_no=params["lead_no"]
    project_name=params["project"]
    mobile=params["mobile"] rescue nil
    email=params["email"] rescue nil
    @leads=company.leads
    project_id=(company.projects.find_by(name: project_name).id rescue nil)
    if project_id.present?
      @leads = @leads.where(project_id: project_id)
      @leads = @leads.where("((email != '' AND email IS NOT NULL) AND email = ?) OR ((mobile != '' AND mobile IS NOT NULL) AND RIGHT(mobile, 10) LIKE ?)", email, "#{mobile.last(10) if mobile.present?}")
      if @leads.present?
        @leads.first.update(:status_id=>company.dead_status_ids.reject(&:blank?).first.to_i, dead_sub_reason: "Inactive due to visit with Lead No: #{lead_no}")
      end
    end
  end

  private

  def broker_params
    params.require(:brokers).permit(
      :name,
      :mobile,
      :email,
      :firm_name,
      :rera_number,
      :company_id
    )
  end

  def lead_params(params)
    {
      name: params["name"],
      mobile: params["mobile"],
      email: params["email"],
      partner_id: params["lead_id"],
      created_at: params["created_at"],
      project_id: @project_id,
      source_id: @source_id,
      user_id: @user_id,
      closing_executive: @closing_user_id,
      status_id: @company.site_visit_done_id,
      broker_id: @broker_id,
      comment: params["comment"]
    }.merge(@custom_attribute)
  end

end