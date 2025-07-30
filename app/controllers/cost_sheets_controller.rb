class CostSheetsController < ApplicationController
  before_action :set_cost_sheets
  before_action :set_cost_sheet, only: [:show, :edit, :update, :destroy]

  respond_to :html
  PER_PAGE = 20
  
  def index
    if params[:search_query].present?
      @cost_sheets = @cost_sheets.basic_search(params[:search_query])
    end
    @cost_sheets_count = @cost_sheets.size
    respond_to do |format|
      format.html do
        @cost_sheets = @cost_sheets.paginate(:page => params[:page], :per_page => PER_PAGE)
      end
      format.pdf do
        @cost_sheet = @cost_sheets.find(params[:cost_sheet_id])
        render pdf: "#{Date.today}-cost_sheet",
              template: "cost_sheets/#{params[:letter_type]}_pdf.html.haml",
              locales: {:@cost_sheet => @cost_sheet},
              :print_media_type => true
      end
    end
  end

  
  def show
  end

  def edit
  end

  def new
    @cost_sheet = @cost_sheets.new
    
    render 'new'
  end

  # POST /cost_sheets
  def create
    @cost_sheet = CostSheet.new(cost_sheet_params)
    @cost_sheet.company_id = @company.id if @cost_sheet.company_id.blank?
    if @cost_sheet.save
      flash[:success] = "CostSheet created successfully"
      redirect_to cost_sheets_path
    else
      render 'new'
    end
  end

  def update
    if @cost_sheet.update_attributes(cost_sheet_params)
      flash[:notice] = "Cost sheet updated successfully"
      redirect_to cost_sheets_path
    else
      render 'edit'
    end
  end
  
  def destroy
    if @cost_sheet.destroy
      flash[:success] = "Cost sheet deleted successfully"
    else
      flash[:notice] = "Cannot delete this Cost sheet - #{@cost_sheet.errors.full_messages.join(', ')}"
    end
    redirect_to :back and return
  end

  def get_plan_details
    plan = current_user.company.payment_plans.find(params[:id])
    @cost_sheet=::CostSheet.new()
    cost_sheets_plans = plan.plan_stages.map do |stage|
      cp=@cost_sheet.payment_plans.build(title: stage.title, percentage: stage.percentage)
      cp
    end
    respond_to do |format|
      format.js do
        @plans=cost_sheets_plans
      end
    end
  end

  private

    def set_cost_sheets
      @company = current_user.company
      @cost_sheets = @company.cost_sheets
    end

    def set_cost_sheet
      @cost_sheet = @cost_sheets.find params[:id]
    end

    def cost_sheet_params
      params.require(:cost_sheet).permit(:project_name, 
      :building_name,
      :topology,
      :gst,
      :total_cost, 
      :client_name,
      :flat_no,
      :payment_plan_id,
      :user_id,
      :carpet_area,
      :notes,
      other_items_attributes: [
        :id,
        :section_name,
        :name,
        :amount,
        :percentage,
        :due_date,
        :cost_type_id,
        :slab_operator,
        :_destroy,
      ])
    end
end