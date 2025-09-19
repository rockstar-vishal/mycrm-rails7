require 'csv'
class CampaignsController < ApplicationController
  before_action :set_campaigns
  before_action :set_campaign, only: [:show, :edit, :update, :destroy]
  before_action :set_campaign_leads, only: [:show]

  respond_to :html
  PER_PAGE = 20


  def index
    @campaigns = @campaigns.paginate(:page => params[:page], :per_page => PER_PAGE)
  end

  def show
  end


  def new
    @campaign = @campaigns.new
    render_modal 'new'
  end

  def edit
    render_modal 'edit'
  end

  def create
    @campaign = @campaigns.new(campaign_params)
    if @campaign.save
      flash[:notice] = "Campaign created successfully"
      xhr_redirect_to redirect_to: campaigns_path and return
    else
      render_modal 'new'
    end
  end

  def update
    if @campaign.update(campaign_params)
      flash[:notice] = "Campaign updated successfully"
      xhr_redirect_to redirect_to: campaigns_path
    else
      render_modal 'edit'
    end
  end

  def destroy
    if @campaign.destroy
      flash[:notice] = "Campaign deleted successfully"
    else
      flash[:danger] = "Cannot delete this campaign - #{@campaign.errors.full_messages.join(', ')}"
    end
    redirect_to request.referer and return
  end

  def download_sample_csv
    respond_to do |format|
      format.csv do
        headers["Content-Disposition"] = "attachment; filename=sample_spend.csv"
        headers["Content-Type"] = "text/csv"

        csv_data = CSV.generate do |csv|
          csv << ["Date", "Amount"] # Headers
          csv << [Date.today.strftime('%d/%m/%Y'), 1000]
          csv << [(Date.today + 1.day).strftime('%d/%m/%Y'), 1500]
        end

        send_data csv_data
      end
    end
  end

  def import_spend
    @campaign = Campaign.find_by(uuid: params[:campaign][:campaign_id])
    csv_file = params[:campaign][:csv_file]

    if csv_file.present?
      errors = []

      CSV.foreach(csv_file.path, headers: true) do |row|
        spend_date = Date.parse(row["Date"]) rescue nil
        spend = @campaign.spends.create(company: @campaign.company, spend_amount: row["Amount"].to_s.gsub(/[,\s]/, '').to_f, spend_date: spend_date)
        errors << row if spend.errors.any?
      end

      if errors.empty?
        flash[:notice] = "Spend data imported successfully"
      else
        flash[:alert] = "Some records failed to import."
      end
    else
      flash[:alert] = "No CSV file uploaded"
    end

    respond_to do |format|
      format.js
    end
  end

  private
    
  def set_campaign
    @campaign = @campaigns.find_by_uuid params[:uuid]
  end

  def set_campaigns
    @campaigns = current_user.company.campaigns
  end

  def set_campaign_leads
    source = ::Source.find(params[:source].to_i)
    start_date = params[:start_date].to_date
    end_date = params[:end_date].to_date
    @leads = @campaign.company.leads.where(source: source, created_at: start_date.beginning_of_day..end_date.end_of_day)
  end

  def campaign_params
    params.require(:campaign).permit(
      :title,
      :start_date,
      :end_date,
      :company_id,
      :budget,
      :campaign_id,
      :source_id,
      :targeted_ad_spent,
      :targeted_leads,
      :targeted_ql,
      :targeted_sv,
      :targeted_bookings,
      project_ids:[]
    )
  end
end
