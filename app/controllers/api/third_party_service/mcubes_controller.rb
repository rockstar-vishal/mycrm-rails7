class Api::ThirdPartyService::McubesController < PublicApiController

  before_action :find_company, except: [:callback, :auto_dailer_hangup, :incoming_call_v2]

  def callback
    @call_log = Leads::CallLog.find_by(sid: mcube_params[:callid])
    
    if @call_log.present?
      if @call_log.update(
        start_time: Time.zone.parse(mcube_params[:starttime]),
        end_time: (Time.zone.parse(mcube_params[:endtime]) rescue nil),
        recording_url: mcube_params[:filename],
        duration: mcube_params[:answeredtime],
        status: mcube_params[:status]
      )
        render :json=>{:status=>"Success"}
      else
        render :json=>{:status=>"Failure"}
      end
    else
      render :json=>{:status=>"Call log not found"}, status: 404
    end
  end

  def ctc_ic
    @user = @company.users.active.find_by(mobile: mcube_params[:empnumber])
    @lead = @company.leads.where("RIGHT(REPLACE(mobile,' ', ''), 10) LIKE ?", mcube_params[:callfrom].last(10)).last
    unless @lead.present?
      @lead = @company.leads.build(
        name: mcube_params[:callername].present? ? mcube_params[:callername] :  '--',
        email: mcube_params[:caller_email],
        :mobile=> mcube_params[:callfrom],
        :source_id=> 2,
        :status_id=>@company.new_status_id,
        :project_id=> @company.default_project&.id,
        user_id: @user&.id
      )
    end
    if @lead.save
      @lead.call_logs.where(sid: mcube_params[:callid]).each{|cl| cl.status=="CONNECTING" && cl.update_attribute(:status, 'NOANSWER')}
      call_logs = @lead.call_logs.build(
        caller: 'Lead',
        direction: 'incoming',
        sid: mcube_params[:callid],
        start_time: mcube_params[:starttime],
        end_time: (Time.zone.parse(mcube_params[:endtime]) rescue nil),
        to_number: mcube_params[:callto],
        from_number: @lead.mobile,
        status: mcube_params[:dialstatus],
        duration: mcube_params[:answeredtime],
        user_id: @lead.user_id,
        recording_url: "#{mcube_params[:filename]}",
        third_party_id: 'mcube',
        phone_number_sid: mcube_params[:landingnumber],
        call_type: 'inbound'
      )
      call_logs.save
      render :json=>{:status=>"Success"}, status: 200 and return
    else
      render json: {status: false, :message=>"Lead not created", :debug_message=>@lead.errors.full_messages.join(","), :data=>{}}, status: 422 and return
    end
  end

  def incoming_call_v2
    mcube_no = params[:clicktocalldid]
    @company = (Company.joins(:mcube_groups).where("mcube_groups.number ILIKE ?", "%#{mcube_no&.last(10)}").where(mcube_groups: { is_active: true }).first ||
  Company.joins(:mcube_groups).where(mcube_groups: { number: mcube_no, is_active: true }).first)
    render json: {status: false, message: "Invalid"}, status: 404 and return if @company.blank?
    
    mcube_sid = @company.mcube_sids.where(number: mcube_no).last || @company.mcube_sids.where(number: mcube_no&.last(10)).last
    project = mcube_sid&.project&.id
    customer_phone = params[:callto]
    emp_phone = params[:emp_phone]
    @lead = @company.leads.active_for(@company).where("RIGHT(REPLACE(mobile,' ', ''), 10) LIKE ? AND project_id = ?", customer_phone.last(10), project).last
    if mcube_sid.is_round_robin_enabled? && ::Leads::CallLog::MISSED_STATUS.include?(params[:dialstatus])
      user_id = mcube_sid.find_round_robin_user
    else
      user_id = (@company.users.active.find_by(mobile: emp_phone) || @company.users.active.superadmins.first).id
    end
    unless @lead.present?
      @lead = @company.leads.build(
          :mobile=> customer_phone,
          :source_id=> (mcube_sid.source_id || 2),
          :enquiry_sub_source_id => mcube_sid.sub_source_id,
          :status_id=>@company.new_status_id,
          :user_id=>user_id,
        )
    end
    @lead.project_id = project if project.present?
    if @lead.save
      call_logs = @lead.call_logs.build(
        caller: 'Lead',
        direction: 'incoming',
        sid: params[:callid],
        start_time: (Time.zone.parse(params[:starttime]) rescue nil),
        end_time: (Time.zone.parse(params[:endtime]) rescue nil)
        to_number: customer_phone,
        from_number: @lead.mobile,
        status: params[:dialstatus],
        third_party_id: 'mcube',
        phone_number_sid: mcube_no
      )
      call_logs.save
      render :json=>{:status=>"Success"}, status: 200 and return
    else
      render json: {status: false, :message=>"Lead not saved", :debug_message=>@lead.errors.full_messages.join(",")}, status: 422 and return
    end
  end

  def incoming_call
    mcube_sid = @company.mcube_sids.where(number: mcube_params[:landingnumber]).last || @company.mcube_sids.where(number: mcube_params[:landingnumber]&.last(10)).last
    project = mcube_sid&.project&.id
    @lead = @company.leads.active_for(@company).where("RIGHT(REPLACE(mobile,' ', ''), 10) LIKE ? AND project_id = ?", mcube_params[:callfrom].last(10), project).last
    if mcube_sid.is_round_robin_enabled? && ::Leads::CallLog::MISSED_STATUS.include?(mcube_params[:dialstatus])
      user_id = mcube_sid.find_round_robin_user
    else
      user_id = (@company.users.active.find_by(email: mcube_params[:empemail]&.downcase) || @company.users.active.superadmins.first).id
    end
    if @lead.present?
      @lead.update(project_id: project || @company.default_project&.id)
    else
      @lead = @company.leads.build(
        name: mcube_params[:callername].present? ? mcube_params[:callername] :  '--',
        email: mcube_params[:caller_email],
        :mobile=> mcube_params[:callfrom],
        :source_id=> mcube_sid.source_id || 2,
        :enquiry_sub_source_id => mcube_sid.sub_source_id,
        :status_id=>@company.new_status_id,
        :user_id=>user_id,
        :project_id=> project || @company.default_project&.id
      )
    end
    if @lead.save
      @lead.call_logs.where(sid: mcube_params[:callid]).each{|cl| cl.status=="CONNECTING" && cl.update_attribute(:status, 'NOANSWER')}
      call_logs = @lead.call_logs.build(
        caller: 'Lead',
        direction: 'incoming',
        sid: mcube_params[:callid],
        start_time: mcube_params[:starttime],
        to_number: mcube_params[:callto],
        from_number: @lead.mobile,
        status: mcube_params[:dialstatus],
        third_party_id: 'mcube',
        phone_number_sid: mcube_params[:landingnumber]
      )
      call_logs.save
      render :json=>{:status=>"Success"}, status: 200 and return
    else
      render json: {status: false, :message=>"Lead not created", :debug_message=>@lead.errors.full_messages.join(","), :data=>{}}, status: 422 and return
    end
  end

  def hangup
    @call_log = Leads::CallLog.where(sid: mcube_params[:callid]).last
    render json: {status: "Failed", message: "Call Log Entry Not Found"}, status: 400 and return if @call_log.blank?
    @user = @company.users.active.find_by(email: mcube_params[:empemail]) || @company.users.active.superadmins.first
    @lead = @call_log.lead
    if @call_log.update(
      user_id: @user.id,
      end_time: mcube_params[:endtime],
      recording_url: "#{mcube_params[:filename]}",
      status: mcube_params[:dialstatus],
      duration: mcube_params[:answeredtime],
      call_type: 'inbound'
    )
      if @lead.present? && Leads::CallLog::ANSWERED_STATUS.include?(@call_log.status) && !@lead.is_repeated_call?
        @lead.update_attribute(:user_id, @user.id)
      end
      render :json=>{:status=>"Success"}
    else
      render :json=>{:status=>"Failure"}
    end
  end

  def auto_dailer_hangup
    company = ::Company.find_by(uuid: params[:uuid])
    phone = dailer_mcube_params[:customer]&.last(10)
    return render json: { status: 'Failed', error: 'Customer phone number missing' }, status: 422 unless phone.present?
    leads = company.leads.active_for(company)
    if dailer_mcube_params[:refid].present?
      project_id = company.projects.find_by(uuid: dailer_mcube_params[:refid])&.id
      leads = leads.where(project_id: project_id)
    end
    lead = leads.where("mobile != '' AND mobile IS NOT NULL AND RIGHT(REPLACE(mobile, ' ', ''), 10) LIKE ?", "%#{phone.last(10)}%").last
    user = company.users.active.find_by(mobile: dailer_mcube_params[:executive]) || company.users.active.superadmins.first
    source_id = company.sources.find_id_from_name(dailer_mcube_params[:source]) || 2
    if lead.present?
      call_logs = lead.call_logs.build(
        caller: 'Lead',
        direction: 'outgoing',
        sid: dailer_mcube_params[:callid],
        start_time: dailer_mcube_params[:starttime],
        end_time: dailer_mcube_params[:endtime],
        to_number: dailer_mcube_params[:customer],
        from_number: dailer_mcube_params[:executive],
        duration: dailer_mcube_params[:answeredtime],
        status: dailer_mcube_params[:status],
        third_party_id: 'mcube',
        recording_url: dailer_mcube_params[:filename],
        user_id: user.id
      )
      if call_logs.save
        if lead.present? && Leads::CallLog::ANSWERED_STATUS.include?(call_logs.status) && !lead.is_repeated_call?
          lead.update_attribute(:user_id, user.id)
        end
        render :json=>{:status=>"Success"}, status: 200
      else
        render :json=>{:status=>"Failed"}, status: 422
      end
    else
      lead = company.leads.build(
         name: dailer_mcube_params[:caller_name].present? ? dailer_mcube_params[:caller_name] :  '--',
        :mobile=> dailer_mcube_params[:customer],
        :source_id=> source_id,
        :status_id=>company.new_status_id,
        :user_id=>user&.id,
        :project_id=> project_id
      )
      if lead.save
        call_logs = lead.call_logs.build(
          caller: 'Lead',
          direction: 'outgoing',
          sid: dailer_mcube_params[:callid],
          start_time: dailer_mcube_params[:starttime],
          to_number: dailer_mcube_params[:customer],
          from_number: dailer_mcube_params[:executive],
          status: dailer_mcube_params[:status],
          third_party_id: 'mcube',
          recording_url: dailer_mcube_params[:filename]
        )
        call_logs.save
        render :json=>{:status=>"Success"}, status: 200
      else
        render json: {status: 'Failed'}, status: 422
      end
    end
  end


  private

  def find_company
    @company = Company.joins(:mcube_groups).where("mcube_groups.number ILIKE ?", "%#{mcube_params[:landingnumber]&.last(10)}").where(mcube_groups: { is_active: true }).first ||
  Company.joins(:mcube_groups).where(mcube_groups: { number: mcube_params[:landingnumber], is_active: true }).first
    render json: {status: false, message: "Invalid"}, status: 404 and return if @company.blank?
  end

  def mcube_params
    JSON.parse(params["data"]).symbolize_keys
  end

  def dailer_mcube_params
    params.permit(
      :callid,
      :executive,
      :customer,
      :starttime,
      :endtime,
      :filename,
      :status,
      :answeredtime,
      :callType,
      :refid,
      :caller_name,
      :source
    )
  end

end
