class Companies::InventoriesController < ApplicationController

  before_action :find_accessible_inventories
  before_action :find_inventory, only: [:edit, :update]

  PER_PAGE = 20

  def index
    if params[:search_string].present?
      @inventories = @inventories.basic_search(params[:search_string])
    end
    @inventories = @inventories.paginate(:page => params[:page], :per_page => PER_PAGE)
  end

  def new
    @inventory = Inventory.new
  end

  def create
     @project = @inventories.new(inventory_params)
    if @project.save
      flash[:notice] = "Inventory created successfully"
      redirect_to companies_inventories_path and return
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    if @inventory.update(inventory_params)
      flash[:notice] = "Inventory updated successfully"
      redirect_to companies_inventories_path
    else
      render 'edit'
    end
  end

  private

  def find_inventory
    @inventory = current_user.company.inventories.find_by(uuid: params[:uuid])
  end

  def find_accessible_inventories
    @inventories = current_user.company.inventories
  end

  def inventory_params
    params.require(:inventory).permit(
      :developer,
      :development,
      :location,
      :floor,
      :unit,
      :carpet,
      :configuration_id,
      :parking,
      :quote,
      :poc,
      :property,
      :contact,
      :id,
      :wing,
      :comments
    )
  end

end
