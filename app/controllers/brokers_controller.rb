class BrokersController < ApplicationController
  before_action :set_brokers
  before_action :set_broker, only: [:show, :edit, :update, :destroy]

  respond_to :html
  PER_PAGE = 20
  # GET /brokers
  # GET /brokers.json
  def index
    if params[:search_query].present?
      @brokers = @brokers.basic_search(params[:search_query])
    end
    @brokers_count = @brokers.size
    respond_to do |format|
      format.html do
        @brokers = @brokers.paginate(:page => params[:page], :per_page => PER_PAGE)
      end
      format.csv do
        if @brokers_count <= 6000
          send_data @brokers.to_csv({}, current_user, request.remote_ip, @brokers.count), filename: "brokers_#{Date.today.to_s}.csv"
        else
          render json: {message: "Export of more than 4000 brokers is not allowed in one single attempt. Please contact management for more details"}, status: 403
        end
      end
    end
  end

  # GET /brokers/1
  # GET /brokers/1.json
  def show
  end

  def edit
    render_modal 'edit'
  end

  def new
    @broker = @brokers.new
    render_modal 'new'
  end

  # POST /brokers
  def create
    @broker = Broker.new(broker_params)
    @broker.company_id = @company.id if @broker.company_id.blank?
    if @broker.save
      flash[:success] = "Broker created successfully"
      xhr_redirect_to redirect_to: brokers_path
    else
      render_modal 'new'
    end
  end

  # PATCH/PUT /brokers/1
  def update
    if @broker.update(broker_params)
      flash[:notice] = "Broker updated successfully"
      xhr_redirect_to redirect_to: brokers_path
    else
      render_modal 'edit'
    end
  end

  def import
  end

  def perform_import
    if params[:broker_file].present?
      file = params[:broker_file].tempfile
      @success=[]
      @errors=[]
      CSV.foreach(file, {:headers=>:first_row, :encoding=> "iso-8859-1:utf-8"}) do |row|
        begin
          name=row["Name"]
          mobile=row["Mobile"].strip rescue nil
          email = row["Email"].strip rescue nil
          rera_number=row["Rera Number"]
          firm_name=row["Firm Name"]
          locality=row["Locality"]
          address=row["Address"]
          other_contacts=row["Other Contacts"]
          rera_status=row["Rera Status"]
          uuid=row["UUID"]&.strip
          cp_code=row["Cp Code"]&.strip
          rm_id=(current_user.manageables.find_by_email(row["RM"].strip).id rescue nil)
          broker = @brokers.new(
            name: name,
            mobile: mobile,
            other_contacts: other_contacts,
            email: email,
            firm_name: firm_name,
            locality: locality,
            address: address,
            rera_number: rera_number,
            rera_status: rera_status,
            rm_id: rm_id,
            cp_code: cp_code
          )
          broker.uuid = uuid if uuid.present?
          if broker.save
            @success << {broker_name: row["Name"], message: "Success"}
          else
            @errors << {broker_name: row["Name"], message: broker.errors.full_messages.join(" | ")}
          end
        rescue Exception => e
          @errors << {broker_name: row["Name"], message: "#{e}"}
        end
      end
    end
  end

  def bulk_update
  end

  def import_bulk_update
    @success = []
    @errors = []
    if params[:brokers_update_file].present?
      CSV.foreach(params[:brokers_update_file].tempfile, {:headers=>:first_row, :encoding=> "iso-8859-1:utf-8"}) do |row|
        uuid=row["CP Uuid"].strip rescue nil
        mobile = row["Mobile"].strip rescue nil
        email = row["Email"].strip rescue nil
        name = row["Name"].strip rescue nil
        locality=row["Locality"].strip rescue nil
        address = row["Address"].strip rescue nil
        firm_name = row["Firm Name"].strip rescue nil
        rera_number=row["Rera No"].strip rescue nil
        rera_status=row["Rera Status"].strip rescue nil
        cp_code=row["Cp Code"].strip rescue nil
        rm_id = (current_user.manageables.find_by_email(row["RM"].strip).id rescue nil)
        begin
          broker = @brokers.find_by(uuid: uuid)
          if broker.present?
            if row["Delete"]&.strip&.downcase == "y"
              if broker.destroy
                @success << {CPUUID: uuid, :message=>"Broker Deleted Successfully"}
              else
                @errors << {CPUUID: uuid, :message=>"#{broker.errors.full_messages}"}
              end
            else
              broker.mobile =mobile.present? ? mobile : broker.mobile
              broker.name = name.present? ? name : broker.name
              broker.email = email.present? ? email : broker.email
              broker.firm_name=firm_name.present? ? firm_name : broker.firm_name
              broker.rera_number=rera_number.present? ? rera_number : broker.rera_number
              broker.address=address.present? ? address : broker.address
              broker.locality=locality.present? ? locality : broker.locality
              broker.rm_id = rm_id.present? ? rm_id : broker.rm_id
              broker.rera_status=rera_status.present? ? rera_status : broker.rera_status
              broker.cp_code=cp_code.present? ? cp_code : broker.cp_code
              if broker.save
                @success << {CPUUID: uuid, :message=>"Success"}
              else
                @errors << {CPUUID: uuid, :message=>"#{broker.errors.full_messages}"}
              end
            end
          else
            @errors << {CPUUID: uuid, :message=>"Broker Not Found"}
          end
        rescue Exception => e
          @errors << {CPUUID: uuid, :message=>"#{e}"}
        end
      end
    end
  end

  # DELETE /brokers/1
  def destroy
    if @broker.destroy
      flash[:success] = "Broker deleted successfully"
    else
      flash[:notice] = "Cannot delete this broker - #{@broker.errors.full_messages.join(', ')}"
    end
    redirect_to :back and return
  end

  private

  def set_brokers
    @company = current_user.company
    @brokers = if current_user.is_super?
                 @company.brokers
               else
                 current_user.company.setting.cp_rm_access_enabled ? current_user.brokers : @company.brokers
               end
  end

  def set_broker
    @broker = @brokers.find_by_uuid params[:uuid]
  end

  def broker_params
    params.require(:broker).permit(:name, :email, :mobile, :firm_name, :locality, :rera_number, :company_id, :rm_id, :other_contacts, :address, :rera_status, :cp_code, :enable_partner_integration, :rera_document)
  end

  def brokers_params
    params.permit(:search_query, :page)
  end
  helper_method :brokers_params
end
