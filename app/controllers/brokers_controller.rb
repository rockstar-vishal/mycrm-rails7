class BrokersController < ApplicationController
  before_action :set_brokers
  before_action :set_broker, only: [:show, :edit, :update, :destroy]

  respond_to :html
  PER_PAGE = 20

  def index
    @brokers = apply_smart_search_filters(@brokers)
    @total_brokers_count = @brokers.size
    
    @selected_batch = params[:batch].presence || "all"
    @view_all = (@selected_batch == "all")
    
    if @view_all
      @total_batches = 1
      @batch_start_record = 1
      @batch_end_record = @total_brokers_count
      @batch_record_count = @total_brokers_count
      @batch_brokers = @brokers
      @display_brokers = @brokers
    else
      @selected_batch = @selected_batch.to_i
      @selected_batch = 1 if @selected_batch < 1
      
      @total_batches = (@total_brokers_count.to_f / Broker::EXPORT_LIMIT).ceil
      @total_batches = 1 if @total_batches < 1
      
      @selected_batch = @total_batches if @selected_batch > @total_batches
      
      @batch_offset = (@selected_batch - 1) * Broker::EXPORT_LIMIT
      @batch_start_record = @batch_offset + 1
      @batch_end_record = [@batch_offset + Broker::EXPORT_LIMIT, @total_brokers_count].min
      @batch_record_count = @batch_end_record - @batch_start_record + 1
      
      @batch_brokers = @brokers.offset(@batch_offset).limit(Broker::EXPORT_LIMIT)
      @display_brokers = @brokers.where(id: @batch_brokers.pluck(:id))
    end
    
    respond_to do |format|
      format.html do
        per_page = params[:per_page].present? ? params[:per_page].to_i : Broker::PER_PAGE
        current_page = params[:page].present? ? params[:page].to_i : 1
        
        @brokers = @display_brokers.paginate(
          page: current_page,
          per_page: per_page,
          total_entries: @batch_record_count
        )
      end
      
      format.csv do
        if @display_brokers.count > Broker::EXPORT_LIMIT
          flash[:alert] = "Cannot export #{@total_brokers_count} brokers at once (limit: #{Broker::EXPORT_LIMIT} records). Please export records batch wise"
          redirect_to brokers_path and return
        end
        if @view_all && @brokers.count <= Broker::EXPORT_LIMIT
          send_data @brokers.to_csv({}, current_user, request.remote_ip, @total_brokers_count), 
                   filename: "brokers_all_records_#{Date.today.to_s}.csv"
        else
          send_data @batch_brokers.to_csv({}, current_user, request.remote_ip, @batch_record_count), 
                   filename: "brokers_batch_#{@selected_batch}_records_#{@batch_start_record}_to_#{@batch_end_record}_#{Date.today.to_s}.csv"
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
      CSV.foreach(file, headers: :first_row, encoding: "iso-8859-1:utf-8") do |row|
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
      CSV.foreach(params[:brokers_update_file].tempfile, headers: :first_row, encoding: "iso-8859-1:utf-8") do |row|
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
    params.permit(:name, :firm_name, :button, :mobile, :phone, :email, :rera_number, :rm_id, :per_page, :search_query, :page, :batch)
  end

  def apply_smart_search_filters(brokers)
    brokers = brokers.where("name ILIKE ?", "%#{params[:name]}%") if params[:name].present?
    brokers = brokers.where("firm_name ILIKE ?", "%#{params[:firm_name]}%") if params[:firm_name].present?
    brokers = brokers.where("mobile ILIKE ?", "%#{params[:mobile]}%") if params[:mobile].present?
    brokers = brokers.where("phone ILIKE ?", "%#{params[:phone]}%") if params[:phone].present?
    brokers = brokers.where("email ILIKE ?", "%#{params[:email]}%") if params[:email].present?
    brokers = brokers.where("rera_number ILIKE ?", "%#{params[:rera_number]}%") if params[:rera_number].present?
    
    brokers
  end

  helper_method :brokers_params
end
