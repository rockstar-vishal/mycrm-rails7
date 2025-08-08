class CitiesController < ApplicationController
  before_action :set_city, only: [:show, :edit, :update, :destroy, :localities]

  PER_PAGE = 50
  respond_to :html

  def index
    @cities = City.all
    if params[:search_string].present?
      @cities = @cities.basic_search(params[:search_string])
    end
    @cities_count=@cities.size
    respond_to do |format|
      format.html do
        @cities = @cities.paginate(:page => params[:page], :per_page => PER_PAGE)
      end
      format.csv do
        if @cities_count <= 6000
          send_data @cities.to_csv({}, current_user, request.remote_ip, @cities_count), filename: "cities_#{Date.today.to_s}.csv"
        else
          render json: {message: "Export of more than 6000 cities is not allowed in one single attempt. Please contact management for more details"}, status: 403
        end
      end
    end
  end

  def show
    respond_with(@city)
  end

  def new
    @city = City.new
    render_modal('new')
  end

  def edit
    render_modal('edit')
  end

  def create
    @city = City.new(city_params)
    if @city.save
      flash[:notice] = 'City Saved Successfully'
      xhr_redirect_to redirect_to: cities_path
    else
      flash[:alert] = 'Error!'
      render_modal 'new'
    end
  end

  def update
    if @city.update(city_params)
      flash[:notice] = 'City Updated Successfully'
      xhr_redirect_to redirect_to: cities_path
    else
      render_modal('edit')
    end
  end

  def destroy
    @city.destroy
    respond_with(@city)
  end

  private
    def set_city
      @city = City.find(params[:id])
    end

    def city_params
      params.require(:city).permit(:name)
    end

    def cities_params
      params.permit(:search_string, :page)
    end
    helper_method :cities_params
end
