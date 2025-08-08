class LocalitiesController < ApplicationController
  before_action :set_locality, only: [:show, :edit, :update]

  PER_PAGE = 50

  def index
    @localities = Locality.includes(:region).order("localities.created_at DESC")
    if params[:search_string].present?
      @localities = @localities.basic_search(params[:search_string])
    end
    
    @localities_count=@localities.size
    respond_to do |format|
      format.html do
        @localities = @localities.paginate(page: params[:page], per_page: PER_PAGE)
      end
      format.csv do
        if @localities_count <= 6000
          send_data @localities.to_csv({}, current_user, request.remote_ip, @localities_count), filename: "localities_#{Date.today.to_s}.csv"
        else
          render json: {message: "Export of more than 6000 localities is not allowed in one single attempt. Please contact management for more details"}, status: 403
        end
      end
    end
  end

  def new
    @locality = Locality.new
    render_modal('new')
  end

  def create
    @locality = Locality.new(locality_params)
    if @locality.save
      flash[:notice] = "#{@locality.name} - Locality Created Successfully"
      xhr_redirect_to redirect_to: localities_path
    else
      flash[:alert] = 'Error!'
      render_modal 'new'
    end
  end

  def show
  end

  def edit
    render_modal('edit')
  end

  def update
    if @locality.update(locality_params)
      flash[:notice] = "#{@locality.name} - Locality Updated Successfully"
      xhr_redirect_to redirect_to: localities_path
    else
      render_modal('edit')
    end
  end

  private

  def locality_params
    params.require(:locality).permit(
      :name,
      :region_id
    )
  end

  def localities_params
    params.permit(:search_string, :page)
  end
  helper_method :localities_params

  def set_locality
    @locality = Locality.find(params[:id])
  end
end
