class ExternalService

  def initialize(company, params={})
    @company = company
    @params = params
  end

  def create_client
    url = @company.postsale_url
    if url.present?
      begin
        RestClient.post(url+"/internal/clients.json", @params, {content_type: "application/json", accept: 'application/json'})
      rescue => e
        []
      end
    end
  end

  def create_broker
    url = @company.postsale_url
    if url.present?
      begin
        RestClient.post(url+"/internal/brokers.json", @params, {content_type: "application/json", accept: 'application/json'})
      rescue => e
        []
      end
    end
  end

  def create_booking_clients
    url = @company.postsale_url
    if url.present?
      begin
        RestClient.post(url+"/internal/clients/bookings.json", @params.to_json, {content_type: "application/json", accept: 'application/json'})
      rescue => e
        [errors: JSON.parse(e.response)["message"]]
      end
    end
  end

  def fetch_booking_flat
    url = @company.postsale_url
    if url.present?
      begin
        RestClient.get(url+"/internal/flats/#{@params[:flat_id]}/booking_flats", {content_type: "application/json", accept: 'application/json'})
      rescue => e
        []
      end
    end
  end

  def fetch_flats
    url = @company.postsale_url
    if url.present?
      begin
        RestClient.get(url+"/internal/flats", {params: {building_id: @params["building_id"], filter: @params["filter"]}})
      rescue => e
        []
      end
    end
  end

  def fetch_projects
    url = @company.postsale_url
    if url.present?
      begin
        return RestClient.get(url+"/internal/flats/get_projects", {content_type: "application/json", accept: "application/json"})
      rescue => e
        []
      end
    end
  end

  def fetch_buildings
    url = @company.postsale_url
    if url.present?
      begin
        return RestClient.get(url+"/internal/flats/get_buildings", {params: {id: @params["project_id"]}})
      rescue => e
        []
      end
    end
  end

  def block_flat
    url = @company.postsale_url
    if url.present?
      begin
        RestClient.post(url+"/internal/flats/#{@params[:id]}/block", @params, {content_type: "application/json", accept: 'application/json'})
      rescue => e
        return []
      end
    end
  end

  def fetch_flat
    url = @company.postsale_url
    if url.present?
      begin
        RestClient.get(url+"/internal/flats/get_flat", {params: {flat_id: @params[:id]}})
      rescue => e
        []
      end
    end
  end

  def create_partner
    url = @company.partner_crm_url
    if url.present?
      begin
        response = RestClient.post(url+"/brokers.json", @params, {content_type: "application/json", accept: 'application/json'})
        JSON.parse(response.body)
      rescue => e
        []
      end
    end
  end

  def create_partners_lead
    url = @company.partner_crm_url
    if url.present?
      begin
        RestClient.post(url+"/brokers/create/leads.json", @params, {content_type: "application/json", accept: 'application/json'})
      rescue => e
        []
      end
    end
  end

  def fetch_partners_projects
    url = @company.partner_crm_url
    if url.present?
      begin
        RestClient.get(url+"/get_projects", {content_type: "application/json", accept: 'application/json'})
      rescue => e
        []
      end
    end
  end

  def get_partners
    url = @company.partner_crm_url
    if url.present?
      begin
        RestClient.get(url+"/get_partners", {content_type: "application/json", accept: 'application/json'})
      rescue => e
        []
      end
    end
  end

  def get_localities
    url = @company.partner_crm_url
    if url.present?
      begin
        RestClient.get(url+"/get_localities", {content_type: "application/json", accept: 'application/json'})
      rescue => e
        []
      end
    end
  end

  def get_partner_sources
    url = @company.partner_crm_url
    if url.present?
      begin
        RestClient.get(url+"/get_sources", {content_type: "application/json", accept: 'application/json'})
      rescue => e
        []
      end
    end
  end

  def get_partner_users
    url = @company.partner_crm_url
    if url.present?
      begin
        RestClient.get(url+"/get_users", {content_type: "application/json", accept: 'application/json'})
      rescue => e
        []
      end
    end
  end

  def fetch_partner_lead
    url = @company.partner_crm_url
    if url.present?
      begin
        RestClient.get(url+"/fetch_lead", {params: {phone: @params["phone"], project_id: @params["project_id"], lead_no: @params["lead_no"], broker_id: @params["broker_id"]}})
      rescue => e
        []
      end
    end
  end

  def fetch_gre_leads
    url = @company.partner_crm_url
    if url.present?
      begin
        RestClient.get(url+"/fetch_gre_leads", {params: {mail: @params["mail"]}})
      rescue => e
        []
      end
    end
  end

  def partner_lead_edit
    url = @company.partner_crm_url
    if url.present?
      begin
        RestClient.post(url+"/leads/#{@params[:id]}/edit", @params, {content_type: "application/json", accept: 'application/json'})
      rescue => e
        return []
      end
    end
  end

  def get_cp_ids
    url = @company.partner_crm_url
    if url.present?
      begin
        RestClient.get(url+"/cps", {content_type: "application/json", accept: 'application/json'})
      rescue => e
        []
      end
    end
  end

  def inactive_partner_lead
    url = @company.partner_crm_url
    if url.present?
      begin
        RestClient.get(url+"/inactive_lead", {params: {phone: @params["phone"], project_name: @params["project_name"], lead_no: @params["lead_no"]}})
      rescue => e
        []
      end
    end
  end

  def fetch_partners_broker broker_id
    url = @company.partner_crm_url
    if url.present?
      begin
        RestClient.get(url+"/broker/#{broker_id}")
      rescue Exception => e
        return {} 
      end
    end
  end

  def update_partners_lead
    url = @company.partner_crm_url
    if url.present?
      begin
        RestClient.post(url+"/leads/#{@params["partner_lead_no"]}/update", @params, {content_type: "application/json", accept: 'application/json'})
      rescue => e
        return []
      end
    end
  end

  def create_partner_visit
    url = @company.partner_crm_url
    if url.present?
      begin
        RestClient.post(url+"/brokers/create/visits.json", @params, {content_type: "application/json", accept: 'application/json'})
      rescue => e
        []
      end
    end
  end

  def partner_params_formation
    lead_params=@params[:lead_params]
    leads_hash={"email": @params[:email], "id": lead_params[:id], "builders_lead"=> {"closing_executive_id": lead_params["closing_executive"] ,"ncd": lead_params["ncd"], "visited": true,"visit_date": Date.today, "comment": lead_params["comment"], "broker_lead_attributes"=> [{"id": lead_params[:id], "name": lead_params["name"], "phone": lead_params["mobile"], "email": lead_params["email"], "project_id": lead_params["project_id"], "source_id": lead_params["source_id"], "broker_id": lead_params["broker_id"]}]}}
    _hash=[]
    _hash << leads_hash["builders_lead"].keys
    _hash << leads_hash["builders_lead"]["broker_lead_attributes"][0].keys
    _hash << leads_hash.keys
    _hash.flatten.map{|h| lead_params.delete(h)}
    leads_hash["builders_lead"].merge!(lead_params)
    leads_hash
  end

end