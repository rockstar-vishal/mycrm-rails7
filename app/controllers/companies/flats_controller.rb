class Companies::FlatsController < ApplicationController

  def fetch_biz_flats
  end

  def fetch_projects
    es = ExternalService.new(current_user.company)
    projects = es.fetch_projects
    if projects.present?
      @projects = JSON.parse(projects)
    end
    render json: @projects, status: 200 and return
  end

  def fetch_buildings
    project_id = params[:id]
    request = {"project_id" => project_id}
    es = ExternalService.new(current_user.company, request)
    buildings = es.fetch_buildings
    @buildings = JSON.parse(buildings)
    render json: @buildings, status: 200 and return
  end

  def fetch_building_flats
    building_id = params[:id]
    if params[:filter].present?
      request = {"building_id" => building_id, "filter" => params[:filter]}
    else
      request = {"building_id" => building_id, "filter" => "all"}
    end
    es = ExternalService.new(current_user.company, request)
    flat_details = es.fetch_flats
    if flat_details.present?
      flat_details = JSON.parse(flat_details)
      @flats = flat_details["flats"]
      floors=flat_details["floors"]
      @floors = @flats.map{|k| k["floor"] if floors.include? k["floor"]}.uniq
    end
    respond_to do |format|
      format.js do
        @flat_details = flat_details
      end
    end
  end

  def flat_block_modal
    @flat_id = params["id"]
    @flat_name = params["name"]
    @building_id = params["building_id"]
    request = {id: @flat_id}
    if current_user.company.setting.present? && current_user.company.enable_flat_details
      es = ExternalService.new(current_user.company, request)
      cost_details = es.fetch_flat
      @carpet_area = params["carpet_area"]
      @config = params["config"]
      @facing=params["facing_name"]
      @costs = JSON.parse(cost_details)
    end
    render_modal('flat_block_modal')
  end

  def block_flat
    flat_id=params[:flat_id]
    flat_name=params[:flat_name]
    user_ids = params[:user_ids]
    lead_names=params[:lead_names]
    date = params[:date]
    end_date=params[:end_date].present? ? params[:end_date] : ""
    comment = params[:comment] rescue ''
    request = {id: flat_id, :user_ids => user_ids, date: date, end_date: end_date, comment: comment, :lead_names=>lead_names}
    es = ExternalService.new(current_user.company, request)
    flat_block = es.block_flat
    flat_block = JSON.parse(flat_block)
    render json: flat_block, status: 200 and return
  end

  def search_lead
    @leads = Lead.where("name ILIKE ?", "%#{params[:query]}%").limit(25)
    render json: @leads.as_json(only: [:id, :name, :email, :mobile])
  end

  def search_broker
    @broker = Broker.where("name ILIKE ?", "%#{params[:query]}%").limit(25)
    render json: @broker.as_json(only: [:id, :name])
  end

  def booking_form
    @flat_data = {}
    begin
      es = ExternalService.new(current_user.company, flat_id: params[:id])
      @flat_data = es.fetch_booking_flat
    rescue => e
      []
    end
    @flat_data = JSON.parse(@flat_data).with_indifferent_access
    @total_area =  @flat_data[:carpet_area].to_i + @flat_data[:enclosed_balcony_area].to_i + @flat_data[:terrace_area].to_i + @flat_data[:balcony_area].to_i
  end


  def create_client
    begin
      purpose_of_purchase = { first_home_end_use: 'first_home_end_use', second_home: 'second_home', investment: 'investment' }.find { |key, _| params[key] == 1 }&.last
      data = {
        clients: 
          [{ 
            name: params[:applicant_name_customer],
            dob: params[:dob_customer],
            age: params[:age_customer],
            designation: params[:occupation_customer],
            correspondent: params[:correspondence_address_customer],
            pin_code: params[:pin_code_customer],
            city: params[:city_customer],
            country: params[:country_customer],
            residence: params[:residence_customer],
            pan_card: params[:pan_customer],
            aadhar: params[:aadhar_customer],
            contact: params[:contact_no_customer],
            email: params[:email_customer],
            password: 'password'
          },
          {
            name: params[:name_co_applicant],
            dob: params[:dob_co_applicant],
            age: params[:age_co_applicant],
            designation: params[:occupation_co_applicant],
            correspondent: params[:correspondence_address_co_applicant],
            pin_code: params[:pin_code_customer],
            city: params[:city_customer],
            country: params[:country_customer],
            residence: params[:residence_customer],
            pan_card: params[:pan_co_applicant],
            aadhar: params[:aadhar_co_applicant],
            contact: params[:contact_no_co_applicant],
            email: params[:email_co_applicant],
            password: 'password'
          }],
        client_signatures: {
            applicant_signature: params[:applicant_signature],
            co_applicant_signature: params[:co_applicant_signature],
            sales_manager_signature: params[:sales_manager_signature]
          },
        user: {
          email: current_user.email
        },
        broker: {
          id: params[:broker_id]&.to_i
        },
        flat: {
          id: params[:id],
          application_date: params[:agreement_schedule_date].blank? ? nil : params[:agreement_schedule_date],
          loan_provider: params[:preferred_bank],
          fund_source: params[:funding_mode]
        },
        flats_bookings: {
          purpose_of_purchase: purpose_of_purchase,
          source: params[:direct_source],
          referral_name: params[:referral_name],
          referral_contact_no: params[:referral_contact_no]
        },
        flats_parkings: {
          parking_name: params[:parkings_dropdown],
          parking_type: params[:parking_level_dropdown]
        }
      }
      es = ExternalService.new(current_user.company, data)
      res = es.create_booking_clients
    rescue => e
      redirect_to booking_form_companies_flat_path, alert: e and return
    end
    if res.is_a?(Array) && (res.first.is_a?(Hash) && res.first.key?(:errors))
      redirect_to booking_form_companies_flat_path, alert: res.first[:errors]
    else
      redirect_to root_path, flash: { sweet_alert_success: 'Booking created successfully!' }
    end
  end
end