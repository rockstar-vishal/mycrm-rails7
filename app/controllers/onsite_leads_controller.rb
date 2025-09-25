class OnsiteLeadsController < ApplicationController
  before_action :set_leads
  before_action :set_lead, only: [:edit, :visit_details, :edit_visit]

  respond_to :html
  PER_PAGE = 20

  def index
    @company_leads = @leads
    @leads= @leads.where("user_id=? OR closing_executive=?", current_user.id, current_user.id).order("created_at desc")
    if params[:search_query].present?
      @leads = @company_leads.basic_search(params[:search_query], current_user)
    end
    if params[:visit_expiring].present?
      @leads=@leads.visit_expiration(@company)
    end
    @leads_count = @leads.size
    respond_to do |format|
      format.html do
        @leads = @leads.paginate(:page => params[:page], :per_page => PER_PAGE)
      end
      format.pdf do
        @lead = @company_leads.find(params[:lead_id])
        render pdf: "#{Date.today}-sv",
              template: "onsite_leads/index_pdf.html.haml",
              locales: {:@lead => @lead},
              :print_media_type => true
      end
    end
  end

  def visit_details
    render_modal('visit_detail', {:class=>'right'})
  end

  def partner_leads

  end

  def partner_lead_edit
    @lead_id=params["id"]
    @name=params["name"]
    render_modal('partner_lead_edit')
  end

  def get_leads
    request = {"mail" => current_user.email}
    es = ExternalService.new(current_user.company, request)
    leads = es.fetch_gre_leads
    @leads = JSON.parse(leads)
    respond_to do |format|
      format.js do
        @leads=@leads
      end
    end
  end

  def fetch_users
    es = ExternalService.new(current_user.company)
    users = es.get_partner_users
    @users = JSON.parse(users)
    render json: @users, status: 200 and return
  end

  def edit_lead
    lead_id=params[:lead_id]
    user_id = params[:user_id]
    closing_executive=params[:closing_executive]
    request = {id: lead_id, :user_id => user_id, closing_executive: closing_executive}
    es = ExternalService.new(current_user.company, request)
    lead_edit = es.partner_lead_edit
    lead_edit = JSON.parse(lead_edit)
    render json: lead_edit, status: 200 and return
  end

  def edit
    respond_to do |format|
      format.js do
        render_modal('edit')
      end
      format.html
    end
  end

  def edit_visit
    @visits=@lead.visits.find(params[:visit_id])
    render_modal('site_visit_form')
  end


  private

  def set_lead
    @lead = @leads.find(params[:id])
  end

  def set_leads
    @company = current_user.company
    @leads =@company.leads
  end
end