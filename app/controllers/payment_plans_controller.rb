class PaymentPlansController < ApplicationController
  before_action :set_payment_plans
  before_action :set_payment_plan, only: [:show, :edit, :update, :destroy]

  respond_to :html
  PER_PAGE = 20
  
  def index
    if params[:search_query].present?
      @payment_plans = @payment_plans.basic_search(params[:search_query])
    end
    @payment_plans_count = @payment_plans.size
    respond_to do |format|
      format.html do
        @payment_plans = @payment_plans.paginate(:page => params[:page], :per_page => PER_PAGE)
      end
    end
  end

  
  def show
  end

  def edit
    render 'edit'
  end

  def new
    @payment_plan = @payment_plans.new
    @payment_plan.plan_stages.build if @payment_plan.plan_stages.blank?
    render 'new'
  end

  # POST /payment_plans
  def create
    @payment_plan = PaymentPlan.new(payment_plan_params)
    @payment_plan.company_id = @company.id if @payment_plan.company_id.blank?
    if @payment_plan.save
      flash[:success] = "Payment plan created successfully"
      redirect_to payment_plans_path
    else
      render 'new'
    end
  end

  def update
    if @payment_plan.update_attributes(payment_plan_params)
      flash[:notice] = "payment plan updated successfully"
      redirect_to payment_plans_path
    else
      render 'edit'
    end
  end
  
  def destroy
    if @payment_plan.destroy
      flash[:success] = "payment plan deleted successfully"
    else
      flash[:notice] = "Cannot delete this payment plan - #{@payment_plan.errors.full_messages.join(', ')}"
    end
    redirect_to :back and return
  end

  private

    def set_payment_plans
      @company = current_user.company
      @payment_plans = @company.payment_plans
    end

    def set_payment_plan
      @payment_plan = @payment_plans.find params[:id]
    end

    def payment_plan_params
      params.require(:payment_plan).permit(:title, 
      plan_stages_attributes: [
        :id,
        :title,
        :percentage,
        :_destroy
      ])
    end
end
