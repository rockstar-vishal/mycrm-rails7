class CommunicationTemplatesController < ApplicationController
  
  before_action :set_template, only: [:show, :edit, :update, :destroy]

  respond_to :html
  PER_PAGE = 20

  def index
    @templates = CommunicationTemplate.all
    
    if params[:is_advanced_search]
      @templates = @templates.advance_search(search_params)
    end

    @templates = @templates.paginate(:page => params[:page], :per_page => PER_PAGE)
  end

  def new
    @template = CommunicationTemplate.new

    if params.keys.include?("company_id")
      if params[:company_id].present?
        @template.company_id = params[:company_id]
      else
        flash[:alert] = 'Please Select Company'
      end
    end
  end

  def edit
  end

  def create
    @template = CommunicationTemplate.new(template_params)
    if @template.save
      flash[:notice] = "Template created successfully"
      xhr_redirect_to redirect_to: communication_templates_path
    else
      flash[:alert] = "Cannot create this template - #{@template.errors.full_messages.join(', ')}"
      xhr_redirect_to redirect_to: new_communication_template_path(company_id: template_params[:company_id])
    end
  end

  def update
    if @template.update_attributes(template_params)
      flash[:notice] = "Template updated successfully"
      xhr_redirect_to redirect_to: communication_templates_path
    else
      flash[:alert] = "Cannot update this template - #{@template.errors.full_messages.join(', ')}"
      xhr_redirect_to redirect_to: edit_communication_template_path
    end
  end

  def destroy
    if @template.destroy
      flash[:notice] = "Template deleted successfully"
    else
      flash[:alert] = "Cannot delete this template - #{@template.errors.full_messages.join(', ')}"
    end
    xhr_redirect_to redirect_to: communication_templates_path
  end

  private
    def set_template
      @template = CommunicationTemplate.find_by_id params[:id]
    end

    def template_params
      params.require(:communication_template).permit(
        :template_name, 
        :notification_type, 
        :company_id, 
        :active,
        trigger_events_attributes: [
          :id, 
          :_destroy, 
          :from_status, 
          :to_status, 
          :object_entity,
          :receiver_type,
          :trigger_type,
          :trigger_hook_type,
          :template_id,
          communication_attributes_attributes: [:id, :_destroy, :text, :variable_mapping_id]
        ]
      )
    end

    def search_params
      params.permit(notification_types: [], company_ids: [])
    end
end