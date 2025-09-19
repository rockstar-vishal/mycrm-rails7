class CloudTelephonySidsController < ApplicationController
  
  before_action :set_cloud_telephony_sids
  before_action :find_cloud_telephony_sid, only: [:edit, :update, :destroy]

  PER_PAGE = 20

  def index
    @cloud_telephony_sids = @cloud_telephony_sids.order(updated_at: :desc).paginate(:page => params[:page], :per_page => PER_PAGE)
  end

  def new
    @cloud_telephony_sid = @cloud_telephony_sids.new
    render_modal 'new'
  end

  def create
    @cloud_telephony_sid = @cloud_telephony_sids.new(cloud_telephony_params)
    if @cloud_telephony_sid.save
      flash[:notice] = 'Cloud Telephony Sid Created Successfully'
      xhr_redirect_to redirect_to: cloud_telephony_sids_path and return
    else
      render_modal 'new'
      flash[:alert] = "Not Created due to #{@cloud_telephony_sid.errors.full_messages.join(',')}"
    end
  end

  def edit
    render_modal 'edit'
  end

  def update
    if @cloud_telephony_sid.update(cloud_telephony_params)
      flash[:notice] = 'Cloud Telephony Sid Updated Successfully'
      xhr_redirect_to redirect_to: cloud_telephony_sids_path
    else
      render_modal 'edit'
    end
  end

  def destroy
    if @cloud_telephony_sid.destroy
      flash[:success] = "CloudTelephony deleted successfully"
    else
      flash[:danger] = "Cannot delete this CloudTelephony - #{@cloud_telephony_sid.errors.full_messages.join(', ')}"
    end
    redirect_to request.referer and return
  end

  private

  def cloud_telephony_params
    params.require(:cloud_telephony_sid).permit(
      :number,
      :description,
      :project_id,
      :is_active,
      :source_id,
      :vendor
    )
  end

  def set_cloud_telephony_sids
    @cloud_telephony_sids = current_user.company.cloud_telephony_sids
  end

  def find_cloud_telephony_sid
    @cloud_telephony_sid = @cloud_telephony_sids.find_by(id: params[:id])
  end
end
