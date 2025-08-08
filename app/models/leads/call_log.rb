class Leads::CallLog < ActiveRecord::Base
  include ReportCsv
  include CallLogApiAttributes

  enum third_party_id:{
    "exotel": 1,
    "mcube": 2,
    "callerdesk": 3,
    "czentrixcloud": 4,
    "way2voice": 5,
    "knowrality": 6,
    "tatatele": 7,
    "myoperator": 8,
    "slashrtc": 9,
    "ivrmanager": 10,
    "teleteemtech": 11
  }

  ANSWERED_STATUS= ['ANSWER', 'answered']
  MISSED_STATUS=['no-answer', 'Missed', 'NOANSWER', 'busy', 'noans', 'client-hangup','canceled']
  ABANDONED_STATUS= ['CANCEL', 'failed', 'Executive Busy', 'Originate', 'Customer Busy', 'CONNECTING','BUSY']
  COMPLETED_STATUS=['completed', 'ANSWER', 'Call Complete', 'answered']

	belongs_to :lead, class_name: "::Lead"
  belongs_to :user, class_name: '::User'

  has_many :call_attempts, through: :lead

  validates :start_time,  presence: true

  has_attached_file :recorded_audio
  validates_attachment_content_type :recorded_audio, content_type: ['audio/mpeg', 'audio/mp3']

  after_commit :send_push_notification,:web_push_notification

  after_commit :log_call_attempt, :new_exotel_lead_sms, on: :create

  other_data_field = [
    :status,
    :direction,
    :phone_number_sid,
    :executive_call_duration,
    :executive_call_status,
    :lead_call_duration,
    :lead_call_status,
    :caller,
    :call_type,
    :session_id
  ]

  scope :incoming, -> {where("leads_call_logs.other_data->>'direction'= ?", 'incoming')}
  scope :not_incoming, -> {where.not("leads_call_logs.other_data->>'direction'= ?", 'incoming')}
  scope :outgoing, -> {where("leads_call_logs.other_data->>'direction'= ?", 'outgoing')}

  scope :todays_calls, -> {where("leads_call_logs.created_at BETWEEN ? AND ?",Date.today.beginning_of_day, Date.today.end_of_day)}
  scope :past_calls, -> {where("leads_call_logs.created_at < ?", Date.today.beginning_of_day)}
  scope :missed, -> {where("leads_call_logs.other_data->>'status' IN (?)", Leads::CallLog::MISSED_STATUS)}
  scope :answered, -> {where("leads_call_logs.other_data->>'status' IN (?)", Leads::CallLog::ANSWERED_STATUS)}
  scope :completed_calls, -> {where("leads_call_logs.other_data->>'status' IN (?)", Leads::CallLog::COMPLETED_STATUS)}
  scope :abandoned_calls, -> {where("leads_call_logs.other_data->>'status' IN (?)", Leads::CallLog::ABANDONED_STATUS)}
  scope :yesterday_calls, -> {where("leads_call_logs.created_at BETWEEN ? AND ?", Date.yesterday.beginning_of_day, Date.today.beginning_of_day)}

  def display_to_number(user)
    return "XXXXXXXXXX" if user.is_telecaller?
    return self.to_number
  end

  def display_from_number(user)
    return "XXXXXXXXXX" if user.is_telecaller?
    return self.from_number
  end


  def default_fields_values
    self.other_data || {}
  end

  other_data_field.each do |method|
    define_method("#{method}=") do |val|
      self.other_data_will_change!
      self.other_data = (self.other_data || {}).merge!({"#{method}" => val})
    end
    define_method("#{method}") do
      default_fields_values.dig("#{method}")
    end
  end

  def send_push_notification
    if Leads::CallLog::MISSED_STATUS.include? self.status
      company = self.lead.company
      client = self.lead
      user = self.user
      if client.present?
        message_text = "Missed an Incoming Call From #{client.name} (#{self.from_number}) : #{client.project&.name}"
      else
        message_text = "Missed an Incoming call from Unknown (#{self.from_number})"
      end
      Pusher.trigger(self.lead.company.uuid, 'missed_call', {message: message_text, notifiables: [user.uuid]})
    end
  end

  def web_push_notification
    if self.user.present? && self.user.company.can_send_push_notification? && Leads::CallLog::MISSED_STATUS.include?(self.status)
      company = self.lead.company
      client = self.lead
      user = self.user
      if client.present?
        message_text = "Missed an Incoming Call From #{client.name} (#{self.from_number}) : #{client.project&.name}"
      else
        message_text = "Missed an Incoming call from Unknown (#{self.from_number})"
      end
      mobile_notification = PushNotificationServiceMobile.new(company, {message: message_text, notifiables: [user.uuid], target_url: "https://#{lead.company.mobile_domain}/Lead/#{lead.uuid}"})
      web_notification = PushNotificationServiceWeb.new(company, {message: message_text, notifiables: [user.uuid]})
      mobile_notification.deliver
      web_notification.deliver
    end
  end

  def log_call_attempt
    if self.user.company.call_response_report.present? && self.direction != 'incoming' && self.lead.call_attempts.where("user_id = (?) AND response_time iS NOT NULL", self.user_id).blank?
      lead_assigned_at = self.lead.audits.select{|audit| audit.audited_changes["user_id"].present? && (audit.audited_changes["user_id"].is_a?(Array) ? audit.audited_changes["user_id"][0]== self.user_id : audit.audited_changes["user_id"][0]== self.user_id)}.sort_by(&:created_at).first.created_at rescue self.lead.created_at
      response_time = (self.created_at.in_time_zone - lead_assigned_at.in_time_zone).to_i rescue nil
      self.lead.call_attempts.create(
        user_id: self.lead.user_id,
        response_time: response_time
      )
    end
  end

  def new_exotel_lead_sms
    lead = self.lead
    if lead.present? && self.exotel? && self.direction = 'incoming' && lead.call_logs.count == 1
      if lead.present? && lead.company.exotel_sms_integration_enabled
        ss = lead.company.system_smses.new(
          messageable_id: lead.id,
          messageable_type: "Lead",
          mobile: lead.mobile,
          text: "Hello,\nThank you for your interest in #{lead.project&.name}.\nHere is your link for the e-Brochure #{lead.project.brochure_link.present? ? lead.project.brochure_link : ''}\nRegards,\nTeam DK Holdings.",
          user_id: lead.user_id,
          template_id: '1207166272522375676'
        )
        ss.save
      end
    end
  end

  class << self

    def advance_search(search_params)
      call_logs = all
      if search_params[:display_from].present?
        display_from = Time.zone.parse(search_params[:display_from])
      end
      if search_params[:past_calls_only].present?
        call_logs = call_logs.past_calls
      end
      if search_params[:todays_calls].present?
        call_logs = call_logs.todays_calls
      end
      if search_params[:missed_calls].present?
        call_logs = call_logs.missed
      end
      if search_params[:completed].present?
        call_logs = call_logs.completed_calls
      end
      if search_params[:abandoned_calls].present?
        call_logs = call_logs.abandoned_calls
      end
      if search_params[:direction].present?
        call_logs = (search_params[:direction] == 'incoming') ? call_logs.incoming : call_logs.not_incoming
      end
      if search_params[:call_direction].present?
        call_logs = search_params["call_direction"] == "Incoming" ? call_logs.incoming : call_logs.not_incoming
      end
      if search_params[:start_date].present?
        created_at_from = Time.zone.parse(search_params["start_date"]).at_beginning_of_day
        call_logs = call_logs.where("leads_call_logs.created_at >= ?", created_at_from)
      end
      if search_params[:end_date].present?
        created_at_upto = Time.zone.parse(search_params["end_date"]).at_end_of_day
        call_logs = call_logs.where("leads_call_logs.created_at <= ?", created_at_upto)
      end
      if search_params[:created_at_from].present?
        created_at_from = Time.zone.parse(search_params["created_at_from"]).at_beginning_of_day
        call_logs = call_logs.where("leads_call_logs.created_at >= ?", created_at_from)
      end
      if search_params[:created_at_upto].present?
        created_at_upto = Time.zone.parse(search_params["created_at_upto"]).at_end_of_day
        call_logs = call_logs.where("leads_call_logs.created_at <= ?", created_at_upto)
      end
      if search_params[:updated_from].present?
        updated_from = Time.zone.parse(search_params[:updated_from]).at_beginning_of_day
        call_logs = call_logs.where("leads_call_logs.updated_at >= ?", updated_from)
      end
      if search_params[:updated_upto].present?
        updated_upto = Time.zone.parse(search_params[:updated_upto]).at_end_of_day
        call_logs = call_logs.where("leads_call_logs.updated_at <= ?", updated_upto)
      end
      if search_params[:lead_ids].present?
        call_logs = call_logs.where(lead_id: search_params[:lead_ids])
      end
      if search_params[:call_from].present?
        call_logs = call_logs.where(from_number: search_params[:call_from])
      end
      if search_params[:call_to].present?
        call_logs = call_logs.where(to_number: search_params[:call_to])
      end
      if search_params[:lead_name].present?
        call_logs = call_logs.joins(:lead).where("leads.name ILIKE ?", "%#{search_params["lead_name"]}%")
      end
      if search_params[:call_status].present?
        call_status = Array.wrap(search_params[:call_status])
        status_array = []
        if (call_status & ["Answered"]).any?
          status_array += Leads::CallLog::ANSWERED_STATUS
        end

        if (call_status & ["Missed"]).any?
          status_array += Leads::CallLog::MISSED_STATUS
        end

        if (call_status & ["Completed"]).any?
          status_array += Leads::CallLog::COMPLETED_STATUS
        end

        if (call_status & ["Abandoned"]).any?
          if search_params[:abandoned_calls_status].present?
            status_array += search_params[:abandoned_calls_status]
          else
            status_array += Leads::CallLog::ABANDONED_STATUS
          end
        end
        call_logs = call_logs.where("leads_call_logs.other_data->>'status' IN (?)", status_array.uniq)
      end
      if display_from.present?
        call_logs = call_logs.where("leads_call_logs.created_at > ?", display_from)
      end
      if search_params[:user_ids].present?
        call_logs = call_logs.where("leads_call_logs.user_id IN (?)", search_params[:user_ids])
      end
      if search_params[:lead_statuses].present?
        call_logs = call_logs.joins(:lead).where("leads.status_id IN (?)", search_params[:lead_statuses])
      end
      if search_params[:source_ids].present?
        call_logs = call_logs.joins(:lead).where("leads.source_id IN (?)", search_params[:source_ids])
      end
      if search_params[:broker_ids].present?
        call_logs = call_logs.joins(:lead).where("leads.broker_id IN (?)", search_params[:broker_ids])
      end
      if search_params[:project_ids].present?
        call_logs = call_logs.joins(:lead).where("leads.project_id IN (?)", search_params[:project_ids])
      end
      if search_params[:first_call_attempt].present?
        call_logs_ids = call_logs.joins(:call_attempts).where.not(call_attempts: {response_time: nil}).ids.uniq
        call_logs = call_logs.where(id: call_logs_ids).select("DISTINCT ON (leads_call_logs.lead_id) leads_call_logs.*")
      end
      if search_params[:bs].present?
        call_logs = call_logs.joins(:lead).where(
          "leads.name ILIKE :search OR from_number LIKE :search OR to_number LIKE :search",
          search: "%#{search_params[:bs]}%"
        )
      end
      call_logs
    end

    def call_logs_csv(options = {}, user)
      CSV.generate(options) do |csv|
        exportable_fields = ["Lead Name", "Executive", "From", "To", "Start Time", "End Time", "Lead Status", "Lead Source", "CP", "Project", "Direction", "OverAll Call Duration", "Call Status", "Call Type"]
        csv << exportable_fields

        all.each do |call_log|
          from_number = call_log.display_from_number(user)
          to_number = call_log.display_to_number(user)
          start_time = call_log.start_time&.strftime("%e %b %Y,%l:%M:%S %p")
          end_time = call_log.end_time&.strftime("%e %b %Y,%l:%M:%S %p")

          this_exportable_fields = [call_log.lead.name, call_log.user&.name, from_number, to_number, start_time, end_time, call_log.lead.status.name, call_log.lead.source.name, ((call_log.lead.broker.name) rescue '-'), call_log.lead.project.name, call_log.direction, call_log.duration, call_log.status, call_log.call_type]

          csv << this_exportable_fields
        end
      end
    end
  end

end
