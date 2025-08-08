class Lead < ActiveRecord::Base


  include LeadApiAttributes
  extend SqlShared
  include HasMagicFields::Extend
  include LeadRequirements
  include PostsaleIntegrationApi
  include NotificationTriggerEvents
  include ReportCsv
  include LeadNotifications
  include ClientSmsNotification
  include EmailNotifications
  include ThirdPartyHookApi

  audited associated_with: :company, only: [:status_id, :user_id, :comment, :tentative_visit_planned, :closing_executive, :project_id, :ncd, :source_id, :broker_id]

  attr_accessor :should_delete, :actual_comment, :cannot_send_notification, :enable_admin_assign, :lead_visit_status_id

  belongs_to :company
  has_magic_fields :through => :company
  has_many :notifications, dependent: :destroy
  has_many :visits, :class_name=>"::Leads::Visit", dependent: :destroy
  has_many :system_messages, as: :messageable, :class_name=>"::SystemSms", dependent: :destroy
  has_many :emails, as: :receiver, class_name: 'Email', dependent: :destroy
  has_many :call_attempts, dependent: :destroy
  has_many :custom_audits, class_name: "CustomAudit", foreign_key: :auditable_id, dependent: :destroy
  has_many :magic_attributes, class_name: 'MagicAttribute', dependent: :destroy
  belongs_to :source
  belongs_to :project
  belongs_to :user
  belongs_to :presale_user, class_name: 'User', foreign_key: :presale_user_id, optional: true
  belongs_to :postsale_user, class_name: 'User', foreign_key: :closing_executive, optional: true
  belongs_to :last_lead_modified_user, class_name: 'User', foreign_key: :last_modified_by
  belongs_to :status
  belongs_to :call_in, optional: true
  belongs_to :city, optional: true
  belongs_to :locality, optional: true
  belongs_to :broker, optional: true
  belongs_to :enq_subsource, :class_name=> 'SubSource', foreign_key: :enquiry_sub_source_id, optional: true
  belongs_to :stage, optional: true
  belongs_to :presales_stage, class_name: 'Stage', foreign_key: :presale_stage_id, optional: true
  belongs_to :dead_reason, :class_name=>"::Companies::Reason", optional: true
  has_many :leads_secondary_sources, class_name: "::Leads::SecondarySource"
  has_many :secondary_sources, through: :leads_secondary_sources, source: :source
  has_many :call_logs, class_name: "Leads::CallLog", dependent: :destroy
  has_many :push_notification_logs, class_name: 'PushNotificationLog', dependent: :destroy
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, :allow_nil => true

  validate :mobile_validation, if: :mobile_number_present?
  validates :company, :status, :source, :project, presence: true

  validate :check_ncd, :check_marketing_manager
  validates :dead_reason, presence: true, if: Proc.new { |a| a.company.dead_status_ids.map(&:to_i).include?(a.status_id) }
  validates :lead_no, presence: true, uniqueness: true

  has_attached_file :image,
                    path: ":rails_root/public/system/:attachment/:id/:style/:filename",
                    url: "/system/:attachment/:id/:style/:filename"
  validates_attachment_content_type  :image,
                    content_type: ['image/jpeg', 'image/png'],
                    size: { in: 0..5.megabytes }

  validate :uniqueness_validation, :either_email_or_phone_present
  default_scope { where(is_deactivated: false) }
  scope :backlogs_for, -> (company){where("leads.ncd IS NULL OR leads.ncd <= ?", Time.zone.now).active_for(company)}
  scope :todays_calls, -> {where("leads.ncd BETWEEN ? AND ?",Date.today.beginning_of_day, Date.today.end_of_day)}
  scope :active_for, -> (company){where.not(:status_id=>[company.dead_status_ids, company.booking_done_id].flatten)}
  scope :booked_for, -> (company){where(:status_id=>company.booking_done_id)}
  scope :expired, ->{where(lease_expiry_date: Date.today-1.month..Date.today-1)}
  scope :expiring, ->{where(lease_expiry_date: Date.today..Date.today+1.month)}
  scope :site_visit_scheduled, ->{where(is_site_visit_scheduled: true)}
  scope :qualified, -> { where(is_qualified: true) }
  scope :thru_visit_form, -> (company){where(status_id: company.site_visit_done_id).where.not(closing_executive: nil)}
  scope :visit_expiration, -> {
                              where(
                                "EXISTS (
                                  SELECT 1
                                  FROM leads_visits AS lv
                                  WHERE lv.lead_id = leads.id
                                  AND lv.date = (
                                    SELECT MIN(date)
                                    FROM leads_visits
                                    WHERE lead_id = leads.id
                                  )
                                  AND lv.date > ?
                                  AND lv.date <= ?
                                )",
                                60.days.ago.beginning_of_day,
                                50.days.ago.end_of_day)}
  before_validation :set_lead_no, :set_defaults, on: :create
  before_validation :strip_mobile_number

  delegate :name, to: :project, prefix: true, allow_nil: true

  accepts_nested_attributes_for :visits, reject_if: :all_blank, allow_destroy: true

  after_commit :delete_audit_logs, on: :destroy
  after_commit :client_integration_to_postsale, if: :client_integration_enable?
  before_create :set_executive
  before_update :set_closing_excutive
  after_create :set_presale_user, if: :presale_user_site_visit_enabled?
  after_commit :notify_lead_create_event, :send_lead_create_brower_notification, on: :create
  before_save :set_site_visit_scheduled
  after_save :set_visit, if: :is_advance_visit_enabled?
  after_commit :create_lead_registration_sms, on: :create
  after_commit :delete_marked_for_deletion, on: :create
  before_create :merge_with_duplicate_lead, :merge_sources
  after_commit :update_partner_lead, on: :update, if: :partner_exists?
  before_save :set_user_details
  after_commit :handle_broker_creation, if: :can_create_broker_integration?

  OTHER_DATA = [
    :gclick_id,
    :fb_ads_id
  ]

  def default_fields_values
    self.other_data || {}
  end

  def strip_mobile_number
    self.mobile = mobile.gsub(/\s+/, '') if mobile.present?
  end

  def set_site_visit_scheduled
    if self.tentative_visit_planned.present?
      self.is_site_visit_scheduled = true
    end
  end

  def can_create_broker_integration?
    self.previous_changes.present? && self.previous_changes["status_id"].present? && self.status_id.to_i == self.company.booking_done_id.to_i && self.source.is_cp && self.broker_id.present?
  end

  def handle_broker_creation
    create_partner_broker_on_booked
    create_postsale_broker_on_booked
  end

  def create_partner_broker_on_booked
    self.broker.broker_integration_to_partner_crm if self.company.partner_crm_url.present?
  end

  def create_postsale_broker_on_booked
    self.broker.broker_integration_to_postsale if self.company.postsale_url.present?
  end

  def partner_exists?
    self.partner_lead_no.present?
  end

  def check_marketing_manager
    if self.user.present? && self.user.is_marketing_manager?
      errors.add(:source_id, "Marketing Manager Accessible Sources: (#{self.user.accessible_sources.pluck(:name).join(',')})") unless self.user.accessible_sources.ids.include? self.source_id
    end
  end

  def days_since_first_visit
    first_visit_date = visits.order(date: :asc).pluck(:date).first
    return "-" unless first_visit_date
    "#{(Date.today - first_visit_date.to_date).to_i} days"
  end

  def day_difference
    first_visit_date = visits.order(date: :asc).pluck(:date).first rescue nil
    if first_visit_date.present? && booking_date.present?
      return TimeDifference.between(booking_date, first_visit_date).in_days.to_i
    else
      return 0
    end
  end

  def update_partner_lead
    if (self.previous_changes.keys & ["ncd", "status_id","comment", "closing_executive", "user_id"]).present?
      ncd = ((self.previous_changes.keys.include? "ncd") ? self.ncd : nil)
      status = ((self.previous_changes.keys.include? "status_id") ? self.status.name : nil)
      comment = ((self.previous_changes.keys.include? "comment") ? previous_changes["comment"][1] : nil)
      request={"partner_lead_no"=>self.partner_lead_no, "ncd"=>ncd, "status"=>status,"comment"=>comment, "closing_executive_email"=>(self.postsale_user.email rescue nil), "user_email"=>(self.user.email rescue nil)}
      es=ExternalService.new(self.company, request)
      es.update_partners_lead
    end
  end

  def set_user_details
    if self.changes.present? && self.changes["user_id"].present?
      self.last_user_assigned_date = Time.zone.now
    end
    self.last_modified_by = Lead.current_user&.id
  end

  OTHER_DATA.each do |method|
    define_method("#{method}=") do |val|
      self.other_data_will_change!
      self.other_data = (self.other_data || {}).merge!({"#{method}" => val})
    end
    define_method("#{method}") do
      default_fields_values.dig("#{method}")
    end
  end

  def mobile_number_present?
    self.mobile.present?
  end


  def mobile_validation
    if company.setting.present?
      mobile_no = self.mobile.to_s
      if company.set_mobile_10_digit_mandatory
        if mobile_no.length < 10 || mobile_no.length > 15
          errors.add(:mobile, "must have at least 10 and not exceed 15 characters")
          return false
        end
      end
      if company.only_10_digit_mobile_number_enabled
        if mobile_no.length != 10
          errors.add(:mobile, "Mobile number cannot be more than 10 digits OR Mobile number cannot be less than 10 digits")
          return false
        end
      end
    end
  end


  def file_url
    if self.booking_form.present?
      self.booking_form.url
    end
  end

  def uniqueness_validation
    ActiveRecord::Base.with_advisory_lock("lead_#{self.mobile&.strip}", transaction: true) do
      email = self.email&.strip
      phone = self.mobile&.strip&.gsub(' ', '')
      other_phone=self.other_phones&.strip&.gsub(' ', '')
      project_id = self.project_id
      dead_status_ids = self.company.dead_status_ids
      booking_done_id = self.company.booking_done_id
      combined_ids = dead_status_ids + [booking_done_id]
      if self.company.setting.present? && self.company.setting.global_validation.present?
        if self.company.setting.open_closed_lead_enabled
          leads = ::Lead.where.not(:id=>self.id, status_id: dead_status_ids).where(:company_id=>self.company_id)
        else
          leads = ::Lead.where.not(:id=>self.id, status_id: [dead_status_ids, booking_done_id].flatten).where(:company_id=>self.company_id)
        end
      else
        leads = ::Lead.where.not(:id=>self.id).where.not(:status_id=>combined_ids).where(:company_id=>self.company_id, :project_id=>project_id)
      end
      if self.company.setting.present? && self.company.secondary_source_enabled
        leads = leads.where(source_id: self.source_id)
      end
      if self.company.setting.present? && self.company.restrict_duplicate_other_contact_leads
        filtered_leads = fetch_leads_with_other_contacts_checks(leads, email, phone, other_phone)
        leads=filtered_leads
      else
        conditions = [
          "email IS NOT NULL AND email != '' AND email = :email",
          "mobile IS NOT NULL AND mobile != '' AND RIGHT(REPLACE(mobile, ' ', ''), 10) = :phone"
        ].join(" OR ")
        leads = leads.where(conditions, email: email, phone: phone&.last(10))
      end
      if leads.present?
        if( leads.first.email.present? && leads.first.email == email)
          self.errors.add(:base, "Email should be unique for a particular project for leads in non dead state")
          self.errors.add(:base, "Lead with the same email is assigned to #{leads.first.user.name}")
          return false
        elsif(leads.first.mobile&.strip&.gsub(' ', '').last(10) == phone.last(10))
          self.errors.add(:base, "Mobile number should be unique for a particular project for leads in non dead state")
          self.errors.add(:base, "Lead with the same mobile number is assigned to #{leads.first.user.name}")
          return false
        elsif(leads.first.other_phones&.strip&.gsub(' ', '').last(10) == phone.last(10))
          self.errors.add(:base, "Mobile number match with Other Contacts of leads in non dead state")
          self.errors.add(:base, "Lead with the same mobile number is assigned to #{leads.first.user.name}")
          return false
        elsif(leads.first.mobile&.strip&.gsub(' ', '').last(10) == other_phone.last(10))
          self.errors.add(:base, "Other Phones match with Mobile number of leads in non dead state")
          self.errors.add(:base, "Lead with the same other phone is assigned to #{leads.first.user.name}")
          return false
        end
        self.errors.add(:base, "Mobile Number / Email / Other Phones duplicate")
        return false
      end
    end
  end

  def fetch_leads_with_other_contacts_checks(leads, email, phone, other_phone)
    email_condition = "email IS NOT NULL AND email != '' AND email = :email"
    phone_on_mobile_condition = "mobile IS NOT NULL AND mobile != '' AND RIGHT(REPLACE(mobile, ' ', ''), 10) = :phone"
    phone_on_other_phones_condition = "other_phones IS NOT NULL AND other_phones != '' AND RIGHT(REPLACE(other_phones, ' ', ''), 10) = :phone"
    other_phones_on_mobile_condition = "mobile IS NOT NULL AND mobile != '' AND RIGHT(REPLACE(mobile, ' ', ''), 10) = :other_phones"
    other_phones_on_other_phones_condition = "other_phones IS NOT NULL AND other_phones != '' AND RIGHT(REPLACE(other_phones, ' ', ''), 10) = :other_phones"
    conditions = [
      email_condition,
      phone_on_mobile_condition,
      phone_on_other_phones_condition,
      other_phones_on_mobile_condition,
      other_phones_on_other_phones_condition
    ].join(" OR ")
    leads = leads.where(
        conditions,
        email: email,
        phone: phone&.last(10),
        other_phones: other_phones&.last(10)
      )
    leads
  end

  def either_email_or_phone_present
    if %w(email mobile).all?{|attr| self[attr].blank?}
      errors.add :base, "Either Phone or Email should be present"
      return false
    end
  end

  def set_defaults
    self.company_id = (self.user.company_id rescue nil) if self.company_id.blank?
    self.status_id = (self.company.new_status_id rescue nil) if self.status_id.blank?
    self.date = Date.today if self.date.blank?
    self.project_id = self.company.default_project&.id if self.project_id.blank?
  end

  def status_id=(input_status_id)
    super
    if self.company.present? && input_status_id.present?
      if input_status_id.to_i == self.company.booking_done_id
        self.conversion_date=::Date.today
      else
        self.conversion_date=nil
      end
    end
  end

  def source_with_call_in
    if self.source_id == ::Source::INCOMING_CALL && self.call_in.present?
      return "#{self.source.name} (#{self.formatted_subsource})"
    elsif self.source.is_cp? && self.broker.present?
      return "#{self.source&.name} (#{self.broker&.name_with_firm_name}#{self.broker.mobile.present? ? " - #{self.broker&.mobile}" : ''})"
    elsif self.source.is_reference && self.referal_name.present? || self.referal_mobile.present?
      return "#{self.source&.name} (#{self.referal_name} #{self.referal_mobile})"
    else
      return self.source.name rescue nil
    end
  end

  def formatted_subsource
    if self.sub_source.present?
      self.sub_source
    elsif self.enq_subsource.present?
      self.enq_subsource&.name
    else
      self.sub_source
    end
  end

  def set_lead_no
    self.lead_no = generate_uniq_lead_no
  end

  def is_advance_visit_enabled?
    self.company.setting.present? && self.company.enable_advance_visits
  end

  def set_visit
    if self.status_id == self.company.expected_site_visit_id && self.changes.present? && self.changes["tentative_visit_planned"].present?
      visit_date = self.tentative_visit_planned if self.tentative_visit_planned.present?
      self.visits.create(date: visit_date.to_date) if visit_date.present?
    end
  end

  def create_lead_registration_sms
    if self.user.company.mobicomm_sms_service_enabled
      if self.mobile.present?
        ss = self.company.system_smses.new(
          messageable_id: self.id,
          messageable_type: "Lead",
          mobile: self.mobile,
          text: "Dear #{self.name}, Thank you for showing interest in our project #{self.project_name}. Our Sales Representative #{self.user&.name}(#{self&.user&.mobile}) shall be in touch with you. In the meantime, please visit #{self.project_name} to know more details about the project. \nRegards, \nTeam #{self.project_name}",
          user_id: self.user.id
        )
        ss.save
      end
    end
  end

  def is_dead?
    return self.company.dead_status_ids.include?(self.status_id.to_s)
  end

  def is_booked?
    return self.status_id == self.company.booking_done_id
  end

  def deactivate
    self.update_column(:is_deactivated, true)
  end

  def activate
    self.update_column(:is_deactivated, false)
  end

  def client_integration_enable?
    self.company.setting.client_integration_enable
  end

  def presale_user_site_visit_enabled?
    self.company.enable_presale_user_visits_report
  end

  def set_presale_user
    self.update(presale_user_id: self.user_id)
  end

  def is_ncd_required?
    if self.company.is_required_fields?("ncd")
      inactive_status_ids = self.company.dead_status_ids << self.company.booking_done_id.to_s
      self.company.setting.present? && self.company.set_ncd_non_mandatory_for_booked_status && inactive_status_ids.reject(&:blank?).include?(self&.status_id.to_s) ? false : true
    else
      return false
    end
  end


  def notify_lead_create_event
    if self.company.events.include?("lead_create")
      url = "http://#{self.company.domain}/leads/#{self.id}/edit"
      message_text = "Lead #{self.name}, assigned to #{self.user&.name} has been created at #{self.created_at.strftime('%d-%b-%y %H:%M %p')}. <a href=#{url} target='_blank'>click here</a>"
      Pusher.trigger(self.company.uuid, 'lead_create', {message: message_text, notifiables: [self.user.uuid]})
    end
  end

  def send_lead_create_brower_notification
    if self.company.push_notification_setting.present? && self.company.push_notification_setting.is_active? && self.company.events.include?('lead_create')
      Resque.enqueue(::ProcessMobilePushNotification, self.id)
    end
  end

  def city_localities
    Locality.joins(region: [:city]).where("cities.id=?", self.city_id)
  end

  def source_sub_sources
    if self.company.setting.present? && self.company.enable_source_wise_sub_source
      self.company.sub_sources.joins(:source).where("sources.id=?", self.source_id)
    else
      self.company.sub_sources
    end
  end

  def merge_with_duplicate_lead
    if self.company.open_closed_lead_enabled
      email = self.email
      phone = self.mobile
      if self.company.global_validation.present?
        leads = self.company.leads.where.not(:id=>self.id).where(status_id: self.company.dead_status_ids).where("((email != '' AND email IS NOT NULL) AND email = ?) OR ((mobile != '' AND mobile IS NOT NULL) AND RIGHT(mobile, 10) ILIKE ?)", email, "#{phone.last(10) if phone.present?}")
      else
        leads = self.company.leads.where.not(:id=>self.id).where(project_id: self.project_id, status_id: self.company.dead_status_ids).where("((email != '' AND email IS NOT NULL) AND email = ?) OR ((mobile != '' AND mobile IS NOT NULL) AND RIGHT(mobile, 10) ILIKE ?)", email, "#{phone.last(10) if phone.present?}")
      end
      if leads.present?
        original_lead = leads.last
        status, message = original_lead.merge_lead_obj self
        self.should_delete = true
      end
      return true
    end
  end

  def merge_lead_obj deletable_lead
    self.actual_comment = "#{self.comment} #{self.company.open_closed_lead_enabled && self.is_dead? ? '[RE-ENQUIRED]' : '[MERGE]'} #{deletable_lead.comment}"
    self.other_phones = "#{deletable_lead.mobile} / #{deletable_lead.other_phones}"
    self.other_emails = "#{deletable_lead.email} / #{deletable_lead.other_emails}"
    self.project_id = deletable_lead.project_id
    self.source_id = deletable_lead.source_id
    if self.company.open_closed_lead_enabled && self.is_dead?
      self.status_id = self.company.new_status_id
      self.reinquired_at = Time.zone.now
    end
    if self.save
      return true, "Success"
    else
      return false, "Cannot merge lead - #{self.errors.full_messages.join(', ')}"
    end
  end

  def merge_sources
    if self.company.secondary_source_enabled
      email = self.email
      phone = self.mobile
      dead_status_ids = self.company.dead_status_ids
      booking_done_id = self.company.booking_done_id
      combined_ids=dead_status_ids + [booking_done_id]
      if self.company.global_validation.present?
        leads = self.company.leads.where.not(:id=>self.id).where.not(:status_id=>dead_status_ids, source_id: self.source_id).where("((email != '' AND email IS NOT NULL) AND email = ?) OR ((mobile != '' AND mobile IS NOT NULL) AND RIGHT(mobile, 10) ILIKE ?)", email, "#{phone.last(10) if phone.present?}")
      else
        leads = self.company.leads.where.not(:id=>self.id).where.not(:status_id=>combined_ids, source_id: self.source_id).where(project_id: self.project_id).where("((email != '' AND email IS NOT NULL) AND email = ?) OR ((mobile != '' AND mobile IS NOT NULL) AND RIGHT(mobile, 10) ILIKE ?)", email, "#{phone.last(10) if phone.present?}")
      end
      if leads.present?
        original_lead = leads.last
        status, message = original_lead.merge_lead_source self
        self.should_delete = true
      end
      return true
    end
  end

  def merge_lead_source deletable_lead
    self.actual_comment = "#{self.comment}[MERGE] #{deletable_lead.comment}"
    self.other_phones = "#{deletable_lead.mobile} / #{deletable_lead.other_phones}"
    self.other_emails = "#{deletable_lead.email} / #{deletable_lead.other_emails}"
    self.project_id = deletable_lead.project_id
    source_ids = self.secondary_source_ids << self.source_id
    diff_source_ids = [deletable_lead.source_id] - source_ids
    if diff_source_ids.present?
      self.assign_attributes(secondary_source_ids: self.secondary_source_ids + diff_source_ids)
    end
    if self.save
      return true, "Success"
    else
      return false, "Cannot merge lead - #{self.errors.full_messages.join(', ')}"
    end
  end

  def can_disable?
    current_user = Lead.current_user
    return !current_user.is_super? && current_user.company.enable_restricted_fields
  end

  class << self
    def current_user=(user)
      RequestStore.store[:current_user] = user
    end

    def current_user
      RequestStore.store[:current_user]
    end

    def search_base_leads(user)
      return user.manageable_leads
    end

    def user_leads(user)
      leads = user.manageable_leads.active_for(user.company)
      return leads
    end

    def site_visit_planned_leads(user)
      if user.company.expected_visit_ids.reject(&:blank?).present?
        leads = user.manageable_leads.where(leads: {status_id: user.company.expected_visit_ids.reject(&:blank?)})
      else
        leads = user.manageable_leads.where("leads.status_id = ?", user.company.expected_site_visit_id)
      end
      return leads
    end

    def basic_search(search_string, user, options = {})
      leads = all
      if options[:backlogs_only].present?
        leads = leads.backlogs_for(user.company)
      end
      leads.where("leads.email ILIKE :term OR leads.mobile LIKE :term OR leads.name ILIKE :term OR leads.lead_no ILIKE :term OR leads.other_phones ILIKE :term", :term=>"%#{search_string}%")
    end

    def filter_leads_for_reports(params, user)
      leads = all
      if params[:updated_from].present?
        updated_from = Time.zone.parse(params[:updated_from]).at_beginning_of_day
        leads = leads.where("leads.updated_at >= ?", updated_from)
      end
      if params[:updated_upto].present?
        updated_upto = Time.zone.parse(params[:updated_upto]).at_end_of_day
        leads = leads.where("leads.updated_at <= ?", updated_upto)
      end
      if params[:project_ids].present?
        leads = leads.where(:project_id=>params[:project_ids])
      end
      if params[:source_ids].present?
        leads = leads.where(:source_id=>params[:source_ids])
      end
      if params[:manager_id].present?
        manageables = user.manageables.find_by_id(params[:manager_id]).subordinates.ids
        leads = leads.where(:user_id=>manageables)
      end
      if params[:user_ids].present?
        leads = leads.where(:user_id=>params[:user_ids])
      end
      if params[:closing_executive].present?
        leads = leads.where(:closing_executive=>params[:closing_executive])
      end
      if params[:sub_source].present?
        leads = leads.where("leads.sub_source ILIKE ?","%#{params[:sub_source]}%")
      end
      if params[:sub_source_ids].present?
        leads=leads.where(enquiry_sub_source_id: params[:sub_source_ids])
      end
      if params[:customer_type].present?
        leads = leads.where(:customer_type=>params[:customer_type])
      end
      if params[:booking_date_from].present?
        booked_id = user.company.booking_done_id
        booking_date_from = Date.parse(params[:booking_date_from])
        leads = leads.where("leads.status_id = ? AND booking_date >= ?",booked_id, booking_date_from)
      end
      if params[:booking_date_to].present?
        booked_id = user.company.booking_done_id
        booking_date_to = Date.parse(params[:booking_date_to])
        leads = leads.where("leads.status_id= ? AND booking_date <= ?",booked_id, booking_date_to)
      end
      if params[:visited_date_from].present?
        visited_date_from = Date.parse(params[:visited_date_from]).beginning_of_day
        lead_ids = leads.joins(:visits).where("leads_visits.date >= ?", visited_date_from).ids.uniq
        leads=leads.where(id: lead_ids)
      end
      if params[:visited_date_upto].present?
        visited_date_to = Date.parse(params[:visited_date_upto]).end_of_day
        lead_ids = leads.joins(:visits).where("leads_visits.date <= ?", visited_date_to).ids.uniq
        leads=leads.where(id: lead_ids)
      end
      if params[:site_visit_from].present?
        site_visit_from = Time.zone.parse(params[:site_visit_from]).at_beginning_of_day
        leads = leads.where("tentative_visit_planned >= ?", site_visit_from)
      end
      if params[:site_visit_upto].present?
        site_visit_upto = Time.zone.parse(params[:site_visit_upto]).at_beginning_of_day
        leads = leads.where("tentative_visit_planned <= ?", site_visit_upto)
      end
       if params[:reinquired_from].present?
        reinquired_from = Time.zone.parse(params[:reinquired_from]).at_beginning_of_day
      end
      if params[:reinquired_upto].present?
        reinquired_upto = Time.zone.parse(params[:reinquired_upto]).at_end_of_day
      end
      if reinquired_from.present?
        leads = leads.where("leads.reinquired_at >= ?", reinquired_from)
      end
      if reinquired_upto.present?
        leads = leads.where("leads.reinquired_at <= ?", reinquired_upto)
      end
      if params[:ncd_from].present?
        ncd_from = Time.zone.parse(params[:ncd_from]).at_beginning_of_day
        leads = leads.where("leads.ncd >= ?", ncd_from)
      end
      if params[:ncd_upto].present?
        ncd_upto = Time.zone.parse(params[:ncd_upto]).at_end_of_day
        leads = leads.where("leads.ncd <= ?", ncd_upto)
      end
      if params[:manager_ids].present?
        manageables = user.manageables.where(id: params[:manager_ids])
        subordinate_ids=manageables.map{|x|x.subordinates.ids}.flatten.uniq
        leads = leads.where(:user_id=>subordinate_ids)
      end
      if params[:lead_statuses].present?
        leads=leads.where(status_id: params[:lead_statuses])
      end
      if params["visit_counts"].present?
        org_visit_leads = leads.joins(:visits)
        visit_leads = org_visit_leads
        visit_leads = visit_leads.where("leads_visits.date >= ?", visited_date_from) if visited_date_from.present?
        visit_leads = visit_leads.where("leads_visits.date <= ?", visited_date_to) if visited_date_to.present?
        if params["visit_counts"] == "Revisit"
          lead_ids = visit_leads.group("leads.id").having("COUNT(leads_visits.id) > 1").ids
        elsif params["visit_counts"] == "New Clients"
          lead_ids = org_visit_leads.group("leads.id").having("COUNT(leads_visits.id) = 1").ids
        else
          lead_ids = visit_leads.group("leads.id").having("COUNT(leads_visits.id) = 1").ids
        end
        leads = leads.where(id: lead_ids)
      end
      if params[:visit_status_ids].present?
        leads =leads.where(status_id: params[:visit_status_ids])
      end
      return leads
    end

    def advance_search(search_params, user)
      leads = all
      if search_params["deactivated"].present?
        leads = leads.unscoped.where(is_deactivated: true)
      end
      if search_params["ncd_from"].present?
        next_call_date_from = Time.zone.parse(search_params["ncd_from"]).at_beginning_of_day
      end
      if search_params["ncd_upto"].present?
        next_call_date_upto = Time.zone.parse(search_params["ncd_upto"]).at_end_of_day
      end
      if search_params["exact_ncd_from"].present?
        exact_next_call_date_from = Time.zone.at(search_params["exact_ncd_from"].to_i)
      end
      if search_params["exact_ncd_upto"].present?
        exact_next_call_date_upto = Time.zone.at(search_params["exact_ncd_upto"].to_i)
      end
      if search_params["created_at_from"].present?
        created_at_from = Time.zone.parse(search_params["created_at_from"]).at_beginning_of_day
      end
      if search_params["created_at_upto"].present?
        created_at_upto = Time.zone.parse(search_params["created_at_upto"]).at_end_of_day
      end
      if search_params["updated_at_from"].present?
        updated_at_from = Time.zone.parse(search_params["updated_at_from"]).at_beginning_of_day
      end
      if search_params["updated_at_upto"].present?
        updated_at_upto = Time.zone.parse(search_params["updated_at_upto"]).at_end_of_day
      end
      if search_params["reinquired_from"].present?
        reinquired_from = Time.zone.parse(search_params["reinquired_from"]).at_beginning_of_day
      end
      if search_params["reinquired_upto"].present?
        reinquired_upto = Time.zone.parse(search_params["reinquired_upto"]).at_end_of_day
      end
      if search_params["visited_date_from"].present?
        visited_date_from = Date.parse(search_params["visited_date_from"]).beginning_of_day
      end
      if search_params["visited_date_upto"].present?
        visited_date_upto = Date.parse(search_params["visited_date_upto"]).end_of_day
      end
      if search_params["token_date_from"].present?
        token_date_from = Date.parse(search_params["token_date_from"])
      end
      if search_params["token_date_to"].present?
        token_date_to = Date.parse(search_params["token_date_to"])
      end
      if search_params["booking_date_from"].present?
        booking_date_from = Date.parse(search_params["booking_date_from"])
      end
      if search_params["booking_date_to"].present?
        booking_date_to = Date.parse(search_params["booking_date_to"])
      end
      if search_params["assigned_to"].present?
        leads = leads.where(:user_id=>search_params["assigned_to"])
      end
      if search_params["presale_user_id"].present?
        leads = leads.where(:presale_user_id=>search_params["presale_user_id"])
      end
      if search_params["manager_id"].present?
        searchable_users = user.manageables.find_by(id: search_params["manager_id"]).subordinates.ids
        leads = leads.where(:user_id=>searchable_users)
      end
      if search_params["closing_executive"].present?
        leads = leads.where(:closing_executive=>search_params["closing_executive"])
      end
      if search_params["manager_ids"].present?
        searchable_users = user.manageables.where(id: search_params["manager_ids"])
        subordinate_ids=searchable_users.map{|x|x.subordinates.ids}.flatten.uniq
        leads = leads.where(:user_id=>subordinate_ids)
      end
      if search_params["lead_no"].present?
        leads = leads.where(:lead_no=>search_params["lead_no"] )
      end
      if search_params["name"].present?
        leads = leads.where("leads.name ILIKE ?", "%#{search_params["name"]}%")
      end
      if search_params["lead_statuses"].present?
        leads = leads.where(:status_id=>search_params["lead_statuses"] )
      end
      if search_params["dead_reasons"].present?
        dead_reason_ids = user.company.dead_status_ids
        leads = leads.where(status_id: dead_reason_ids, dead_reason_id: search_params["dead_reasons"])
      end
      if token_date_from.present?
        token_ids = user.company.token_status_ids.reject(&:blank?)
        leads = leads.where("status_id = ? AND token_date >= ?",token_ids, token_date_from)
      end
      if token_date_to.present?
        token_ids = user.company.token_status_ids.reject(&:blank?)
        leads = leads.where("status_id = ? AND token_date <= ?",token_ids, token_date_to)
      end
      if booking_date_from.present?
        booked_id = user.company.booking_done_id
        leads = leads.where("leads.status_id = ? AND booking_date >= ?",booked_id, booking_date_from)
      end
      if booking_date_to.present?
        booked_id = user.company.booking_done_id
        leads = leads.where("leads.status_id = ? AND booking_date <= ?",booked_id, booking_date_to)
      end
      if search_params["budget_from"].present?
        leads = leads.where("leads.budget >= ?", search_params["budget_from"] )
      end
      if search_params["budget_upto"].present?
        leads = leads.where("leads.budget <= ?", search_params["budget_upto"] )
      end
      if next_call_date_from.present?
        leads = leads.where("leads.ncd >= ?", next_call_date_from)
      end
      if next_call_date_upto.present?
        leads = leads.where("leads.ncd <= ?", next_call_date_upto)
      end
      if exact_next_call_date_from.present?
        leads = leads.where("leads.ncd >= ?", exact_next_call_date_from)
      end
      if exact_next_call_date_upto.present?
        leads = leads.where("leads.ncd <= ?", exact_next_call_date_upto)
      end
      if created_at_from.present?
        leads = leads.where("leads.created_at >= ?", created_at_from)
      end
      if created_at_upto.present?
        leads = leads.where("leads.created_at <= ?", created_at_upto)
      end
      if updated_at_from.present?
        leads = leads.where("leads.updated_at >= ?", updated_at_from)
      end
      if updated_at_upto.present?
        leads = leads.where("leads.updated_at <= ?", updated_at_upto)
      end
      if reinquired_from.present?
        leads = leads.where("leads.reinquired_at >= ?", reinquired_from)
      end
      if reinquired_upto.present?
        leads = leads.where("leads.reinquired_at <= ?", reinquired_upto)
      end
      if search_params["email"].present?
        leads = leads.where("leads.email ILIKE ?", "%#{search_params["email"]}%" )
      end
      if search_params["mobile"].present?
        leads = leads.where("leads.mobile ILIKE ?", "%#{search_params["mobile"]}%" )
      end
      if search_params["other_phones"].present?
        leads = leads.where("leads.other_phones ILIKE ?", "%#{search_params["other_phones"]}%" )
      end
      if search_params["project_ids"].present?
        if user.company.is_sv_project_enabled
          leads=leads.where("project_id IN (:project_ids) OR leads.id IN (SELECT DISTINCT lead_id
          FROM leads_visits
          INNER JOIN leads_visits_projects ON leads_visits.id = leads_visits_projects.visit_id
          WHERE leads_visits_projects.project_id IN (:project_ids)
          )", project_ids: search_params["project_ids"])
        else
          leads = leads.where(project_id: search_params["project_ids"])
        end
      end
      if search_params[:sv_user].present?
        leads = leads.joins(:visits).where(visits: {user_id: search_params[:sv_user]})
      end
      if search_params["visit_expiring"].present?
        leads=leads.visit_expiration
      end
      if search_params["backlogs_only"].present?
        leads = leads.backlogs_for(user.company)
      end
      if search_params["merged"].present?
        leads = leads.joins(:leads_secondary_sources)
      end
      if search_params["todays_call_only"].present?
        leads = leads.active_for(user.company).todays_calls
      end
      if search_params["comment"].present?
        leads = leads.where("leads.comment ILIKE ?", "%#{search_params["comment"]}%")
      end
      if search_params["visit_form"].present?
        leads = leads.joins(:visits).thru_visit_form(user.company)
      end
      if search_params[:dead_reason_ids].present?
        leads = leads.where(:dead_reason_id=>search_params[:dead_reason_ids])
      end
      if search_params["source_id"].present?
        leads = leads.where(:source_id=> search_params["source_id"])
      end
      if search_params["source_ids"].present?
        leads = leads.where(:source_id=>search_params["source_ids"])
      end
      if search_params["sub_source"].present?
        leads = leads.where("leads.sub_source ILIKE ?", "%#{search_params["sub_source"]}%")
      end
      if search_params["sub_source_ids"].present?
        leads = leads.where(enquiry_sub_source_id: search_params["sub_source_ids"])
      end
      if search_params["stage_ids"].present?
        leads = leads.where(presale_stage_id: search_params["stage_ids"])
      end
      if search_params["city_ids"].present?
        leads = leads.where(:city_id=>search_params["city_ids"])
      end
      if search_params["locality_ids"].present?
        leads = leads.where(:locality_id=>search_params["locality_ids"])
      end
      if search_params["country_ids"].present?
        leads = leads.joins(:project).where("projects.country_id IN (?)", search_params["country_ids"])
      end
      if search_params["lead_ids"].present?
        leads = leads.where(:id=>search_params["lead_ids"])
      end
      if search_params["customer_type"].present?
        leads = leads.where(customer_type: search_params["customer_type"])
      end
      if search_params["state"].present?
        leads = leads.where("leads.state ILIKE ?", "%#{search_params["state"]}%")
      end
      if search_params[:is_qualified].present?
        leads = leads.qualified
      end
      if search_params[:visited] || visited_date_from.present? || visited_date_upto.present?
        visits = Leads::Visit.where(lead_id: leads.select(:id))

        if user.company.enable_advance_visits
          visits = visits.where(is_visit_executed: true)
        end

        visits = visits.where("leads_visits.date >= ?", visited_date_from) if visited_date_from.present?
        visits = visits.where("leads_visits.date <= ?", visited_date_upto) if visited_date_upto.present?
        leads = leads.where(id: visits.pluck(:lead_id))
      end
      if search_params["visit_counts"].present?
        visit_leads = (visited_date_from.present? || visited_date_upto.present?) ? leads.joins(:visits).where("leads_visits.id IN (?)", visits.ids) : leads.joins(:visits)
        if search_params["visit_counts"] == "Revisit"
          lead_ids = visit_leads.group("leads.id").having("COUNT(leads_visits.id) > 1").ids
        else
          lead_ids = visit_leads.group("leads.id").having("COUNT(leads_visits.id) = 1").ids
        end
        leads = leads.where(id: lead_ids)
      end
      if search_params["visit_counts_num"].present?
        visit_leads = leads.joins(:visits)
        visit_count_num = search_params["visit_counts_num"].to_i
        lead_ids = visit_leads.group("leads.id").having("COUNT(leads_visits.id) > ?", visit_count_num).ids
        leads = leads.where(id: lead_ids)
      end
      if search_params["expired_from"].present?
        expired_from = Date.parse(search_params["expired_from"])
      end
      if expired_from.present?
        leads = leads.where("lease_expiry_date >= ?", expired_from)
      end
      if search_params["expired_upto"].present?
        expired_upto = Date.parse(search_params["expired_upto"])
      end
      if expired_upto.present?
        leads = leads.where("lease_expiry_date < ?", expired_upto)
      end
      if search_params["lead_stages"].present?
        leads = leads.where(presale_stage_id: search_params["lead_stages"])
      end
      if search_params["site_visit_from"].present?
        site_visit_from = Time.zone.parse(search_params["site_visit_from"]).at_beginning_of_day
        leads = leads.where("tentative_visit_planned >= ?", site_visit_from)
      end
      if search_params["site_visit_upto"].present?
        site_visit_upto = Time.zone.parse(search_params["site_visit_upto"]).at_beginning_of_day
        leads = leads.where("tentative_visit_planned <= ?", site_visit_upto)
      end
      if search_params["site_visit_planned"].present?
        leads = leads.site_visit_scheduled
      end
      if search_params["revisit"].present?
        leads = leads.site_visit_scheduled.where(revisit: true)
      end
      if search_params["booked_leads"].present?
        leads = leads.site_visit_scheduled.booked_for(current_user.company)
      end
      if search_params["token_leads"].present?
        if user.company.token_status_ids.reject(&:blank?).present?
          leads = leads.where(status_id: user.company.token_status_ids)
        end
      end
      if search_params["broker_ids"].present?
        leads = leads.joins(:broker).where(source_id: user.company.sources.cp_sources&.ids, broker_id: search_params["broker_ids"])
      end
      if search_params["postponed"].present?
        leads = leads.joins(:visits).where("leads_visits.is_postponed='t'")
      end
      if search_params["visit_cancel"].present?
        leads = leads.joins(:visits).where("leads_visits.is_canceled='t'")
      end
      if search_params["site_visit_done"].present?
        leads = leads.joins(:visits).where(visits: {is_visit_executed: true})
      end
      conditions = []
      values = []
      user.company.magic_fields.each do |field|
        search_value = search_params[field.name]
        if search_value.present?
          if field.datatype == 'string' || field.datatype == 'date'
            conditions << "(magic_attributes.magic_field_id = ? AND magic_attributes.value ILIKE ?)"
            values << field.id << "%#{search_value}%"
          elsif field.datatype == 'integer'
            conditions << "(magic_attributes.magic_field_id = ? AND magic_attributes.value = ?)"
            values << field.id << search_value
          end
        end
        if ['agreement_date', 'booking_cancelled_date'].include?(field.name)
          if search_params["#{field.name}_from"].present?
            from_date = parse_and_convert_date(search_params["#{field.name}_from"])
            if from_date
              conditions << "(magic_attributes.magic_field_id = ? AND CASE
                  WHEN magic_attributes.value = '' THEN NULL
                  ELSE TO_DATE(
                    magic_attributes.value,
                    CASE
                      WHEN magic_attributes.value LIKE '__/__/____' THEN 'DD/MM/YYYY'
                      WHEN magic_attributes.value LIKE '__-__-____' THEN 'DD-MM-YYYY'
                      WHEN magic_attributes.value LIKE '____-__-__' THEN 'YYYY-MM-DD'
                      WHEN magic_attributes.value LIKE '____/__/__' THEN 'YYYY/MM/DD'
                      ELSE NULL
                    END
                  )
                END >= ?)"
              values << field.id << from_date
            else
              # Handle invalid date format, log error, or skip this condition
              puts "Invalid date format for #{field.name}_from"
            end
          end
          if search_params["#{field.name}_upto"].present?
            upto_date = parse_and_convert_date(search_params["#{field.name}_upto"])
            if upto_date
              conditions << "(magic_attributes.magic_field_id = ? AND CASE
                  WHEN magic_attributes.value = '' THEN NULL
                  ELSE TO_DATE(
                    magic_attributes.value,
                    CASE
                      WHEN magic_attributes.value LIKE '__/__/____' THEN 'DD/MM/YYYY'
                      WHEN magic_attributes.value LIKE '__-__-____' THEN 'DD-MM-YYYY'
                      WHEN magic_attributes.value LIKE '____-__-__' THEN 'YYYY-MM-DD'
                      WHEN magic_attributes.value LIKE '____/__/__' THEN 'YYYY/MM/DD'
                      ELSE NULL
                    END
                  )
                END <= ?)"
              values << field.id << upto_date
            else
              # Handle invalid date format, log error, or skip this condition
              puts "Invalid date format for #{field.name}_upto"
            end
          end
        end
      end
      if conditions.present?
        # leads = leads.joins(:magic_attributes).where(conditions.join(' AND '), *values)
        conditions.each_with_index do |condition, index|
          leads = leads.joins("LEFT JOIN magic_attributes ma_#{index} ON ma_#{index}.lead_id = leads.id")
          leads = leads.where(condition.gsub("magic_attributes", "ma_#{index}"), *values.shift(2))
        end
      end
      return leads
    end

    def parse_and_convert_date(date_string)
      begin
        date_parts = date_string.split('/')
        Date.new(date_parts[2].to_i, date_parts[1].to_i, date_parts[0].to_i).strftime('%Y-%m-%d')
      rescue ArgumentError, NoMethodError
        nil # Or handle the error as needed
      end
    end

    def to_csv(options = {}, exporting_user)
      CSV.generate(options) do |csv|
        exportable_fields = ['Customer Name', 'Lead Number', 'Project', 'Assigned To', 'Lead Status', 'Presale Stage', 'Next Call Date', 'Comment', 'Source','Broker', 'Broker Number', 'Broker CreatedAt','Visited', 'Visited Date', 'Visit Counts', 'Visit Comments','Dead Reason', 'Dead Sub Reason', 'City', 'Created At',  'Last Updated At', 'Sub Source', 'Last User Assigned Date' ,'Last Modified By']
        if exporting_user.is_super? || exporting_user.is_sl_admin? || exporting_user.is_marketing_manager?
          exportable_fields << 'Mobile'
          exportable_fields << 'Email'
        end
        if exporting_user.company.setting.present? && exporting_user.company.secondary_source_enabled
          exportable_fields << 'Secondary Sources'
        end
        if exporting_user.company.is_allowed_field?("customer_type")
          exportable_fields << 'Customer Type'
        end
        if exporting_user.company.is_allowed_field?("closing_executive")
          exportable_fields << 'Closing Executive'
        end
        exportable_fields << 'Tentative Visit Date'
        exportable_fields << 'Tentative Visit Day'
        exportable_fields << 'Tentative Visit Time'
        if exporting_user.company.is_allowed_field?("referal_name")
          exportable_fields << 'Referal Name'
        end
        if exporting_user.company.is_allowed_field?("referal_mobile")
          exportable_fields << 'Referal Mobile'
        end
        if exporting_user.company.is_allowed_field?("address")
          exportable_fields << 'Address'
        end
        if exporting_user.company.fb_ads_ids.present?
          exportable_fields << 'Facebook Ads Id'
        end
        magic_fields = exporting_user.company.magic_fields.order(:id).pluck(:id, :pretty_name).to_h
        exportable_fields = exportable_fields | magic_fields.values
        csv << exportable_fields

        magic_attributes = MagicAttribute.where(lead_id: all.ids).group("lead_id").select("lead_id, ARRAY_AGG(magic_field_id ORDER BY magic_field_id) AS magic_field_ids, ARRAY_AGG(value ORDER BY magic_field_id) AS values").as_json(except: [:id])
        all.includes(project: :city).find_each do |client|
          dead_reason = ""
          dead_sub_reason = ""
          if exporting_user.company.dead_status_ids.include?(client.status_id.to_s)
            dead_reason = client.dead_reason&.reason
            dead_sub_reason = client.dead_sub_reason
          end
          final_phone = client.mobile
          final_email = client.email
          final_source =(client.source.name rescue "-")
          if client.company.cp_sources.ids.include?(client.source_id)
            final_broker = ("#{client.broker.name}#{' - ' + client.broker.firm_name if client.broker.firm_name.present?}" rescue "-")
            broker_number = client.broker&.mobile
            broker_created=client.broker&.created_at&.strftime("%d %B %Y")
          end
          this_exportable_fields = [ client.name, client.lead_no, (client.project.name rescue '-'),(client.user.name rescue '-'), client.status.name, (client.presales_stage&.name rescue '-'), (client.ncd.strftime("%d %B %Y") rescue nil), client.comment, final_source, final_broker, broker_number,broker_created, (client.visits.present? ? "Yes" : "No"), (client.visits.collect { |x| x.date.strftime("%d/%m/%Y") }.join(',') rescue "-"),(client.visits.present? ? client.visits.count : ""),(client.visits.where.not(comment: nil).collect{ |x| x.comment}.join(",") rescue "-"),dead_reason, dead_sub_reason, (client.city.name rescue "-"), (client.created_at.in_time_zone.strftime("%d %B %Y : %I.%M %p") rescue nil), (client.updated_at.in_time_zone.strftime("%d %B %Y : %I.%M %p") rescue nil), client.formatted_subsource, (client.last_user_assigned_date.in_time_zone.strftime("%d %B %Y : %I.%M %p") rescue "-"), (client.last_lead_modified_user.name rescue "-")]
          if exporting_user.is_super? || exporting_user.is_sl_admin? || exporting_user.is_marketing_manager?
            this_exportable_fields << final_phone
            this_exportable_fields << final_email
          end
          if exporting_user.company.setting.present? && exporting_user.company.secondary_source_enabled
            this_exportable_fields << ((client.secondary_sources.pluck(:name).join(',')) rescue "")
          end
          if exporting_user.company.is_allowed_field?("customer_type")
            this_exportable_fields << client.customer_type
          end
          if exporting_user.company.is_allowed_field?("closing_executive")
            this_exportable_fields << client.postsale_user&.name
          end
          this_exportable_fields << client.tentative_visit_planned&.strftime("%d-%m-%Y")
          this_exportable_fields << client.tentative_visit_planned&.strftime("%A")
          this_exportable_fields << client.tentative_visit_planned&.strftime("%I:%M %p")
          if exporting_user.company.is_allowed_field?("referal_name")
            this_exportable_fields << client.referal_name
          end
          if exporting_user.company.is_allowed_field?("referal_mobile")
            this_exportable_fields << client.referal_mobile
          end
          if exporting_user.company.is_allowed_field?("address")
            this_exportable_fields << client.address
          end
          if exporting_user.company.fb_ads_ids.present?
            this_exportable_fields << client.fb_ads_id
          end
          magic_attribute_value = magic_attributes.select{ |ma| ma["lead_id"] == client.id }.first
          if magic_attribute_value.present?
            field_values = magic_attribute_value["magic_field_ids"].zip(magic_attribute_value["values"]).to_h
            values = magic_fields.keys.map { |id| field_values[id] || "" }
            this_exportable_fields = this_exportable_fields + values
          end
          csv << this_exportable_fields
        end
      end
    end

    def save_search_history(search_params, user, search_name)
      user.search_histories.create(
        name: search_name,
        search_params: search_params
      )
    end


    def ncd_not_update_till_thirty_minutes(company)
      leads = all.active_for(company).where("leads.ncd < ?", Time.zone.now - 30.minutes)
      return leads
    end

    def initiate_bulk_call(user)
      request_array = []
      all.each do |lead|
        request_array << {"camp_name": "Fashion_TV", "mobile": "#{lead.mobile&.last(10)}", "agent_id"=> "#{user.agent_id}", "uniqueid"=> "#{lead.id}"}
      end
      begin
        url = "http://czadmin.c-zentrixcloud.com/apps/addlead_bulk.php"
        response = RestClient.post(url, request_array.to_json)
        true
      rescue => e
        false
      end
    end


  end

  def comment=(default_value)
    if default_value.present?
      comment = "#{self.comment_was} \n #{Time.zone.now.strftime("%d-%m-%y %H:%M %p")} (#{(Lead.current_user.name rescue nil)}) : #{default_value}"
      write_attribute(:comment, comment)
    end
  end

  def presale_stage_id=(default_value)
    super
    if default_value.present?
      if default_value.to_i == 16
        self.is_qualified = true
      else
        self.is_qualified = false
      end
    end
  end

  def actual_comment=(default_value)
    if default_value.present?
      write_attribute(:comment, default_value.strip)
    end
  end

  def check_ncd
    if self.company.back_dated_ncd_allowed && self.changes.present? && self.changes["ncd"].present?
      if self.changes["ncd"][1].present? && Time.zone.now > self.changes["ncd"][1]
        errors.add(:ncd, 'back dated ncd is not allowed')
      end
    end
  end

  def is_phone_number_valid?
    TelephoneNumber.parse(self.mobile, :in)&.valid? || TelephoneNumber.parse(self.mobile)&.valid?
  end

  def make_call(current_user)
    if current_user.mcube_sid&.is_active?
      self.make_mcube_call(current_user)
    elsif current_user.is_cloud_telephony_active?('knowrality')
      self.make_knowrality_call(current_user)
    elsif current_user.is_cloud_telephony_active?('tatatele')
      self.make_tatatele_call(current_user)
    elsif current_user.is_cloud_telephony_active?('slashrtc')
      self.make_slashrtc_call(current_user)
    elsif current_user.is_cloud_telephony_active?('callerdesk')
      self.make_callerdesk_call(current_user)
    elsif current_user.is_cloud_telephony_active?('teleteemtech')
      self.make_teleteemtech_call(current_user)
    elsif current_user.agent_id.present?
      self.make_czentrixcloud_call(current_user)
    elsif current_user.company.way_to_voice_enabled
      self.make_way_to_voice_call(current_user)
    else
      option = {
        From: current_user.mobile,
        To: self.mobile,
        CallerId: current_user.exotel_sid.number,
        StatusCallback: current_user.company.exotel_integration_callback_url,
        "StatusCallbackEvents[0]"=> 'terminal',
        "Record"=>'true'
      }
      begin
        url = "https://#{current_user.company.exotel_integration_integration_key}:#{current_user.company.exotel_integration_token}@api.exotel.com/v1/Accounts/#{current_user.company.exotel_integration_sid}/Calls/connect.json"
        response = ExotelSao.secure_post(url, option)
        response = response["Call"]
        call_logs = self.call_logs.build(
          caller: 'User',
          direction: response["Direction"],
          sid: response["Sid"],
          start_time: response["StartTime"],
          to_number: response["To"],
          from_number: response["From"],
          status: response["Status"],
          user_id: current_user&.id
        )
        call_logs.save
      rescue => e
        false
      end
    end

  end

  def make_mcube_call(current_user)
    begin
      if current_user.company.enable_advance_mcube
        url = "https://api.mcube.com/Restmcube-api/outbound-calls"
        request_body = {
          HTTP_AUTHORIZATION: current_user.company.mcube_integration_integration_key,
          exenumber: current_user.mobile,
          custnumber: self.mobile&.last(10),
          refurl: current_user.company.mcube_integration_callback_url
        }.to_json
        success, response = HttpSao.secure_post(url, request_body)
        success = response["status"]
        if !success
          return false, response["msg"]
        end
      else
        url = if current_user.company.mcube_outbound_number_rotation_enabled
                "https://mcube.vmc.in/api/outboundcall?apikey=#{current_user.company.mcube_integration_integration_key}&exenumber=#{current_user.mobile}&custnumber=#{self.mobile&.last(10)}&url=#{current_user.company.mcube_integration_callback_url}"
              else
                "https://mcube.vmc.in/api/outboundcall?apikey=#{current_user.company.mcube_integration_integration_key}&exenumber=#{current_user.mobile}&custnumber=#{self.mobile&.last(10)}&did=#{current_user.mcube_sid.number}&url=#{current_user.company.mcube_integration_callback_url}"
              end
        response = McubeSao.secure_get(url)
      end
      call_log = self.call_logs.build(
        caller: 'User',
        phone_number_sid: current_user.mcube_sid.number,
        direction: 'outgoing',
        sid: response["callid"],
        start_time: Time.now.in_time_zone,
        to_number: self.mobile&.last(10),
        from_number: current_user.mobile,
        user_id: current_user&.id,
        third_party_id: 'mcube'
      )
      if call_log.save
        return true, "Success"
      else
        return false, call_log.errors.full_messages.join(', ')
      end
    rescue => e
      false
    end
  end

  def make_knowrality_call(current_user)
    url = "https://kpi.knowlarity.com/Basic/v1/account/call/makecall"
    request_body = {
      "k_number" => "+91#{current_user.cloud_telephony_no&.last(10)}",
      "agent_number"=> "+91#{current_user.mobile.last(10)}",
      "customer_number" => "+91#{self.mobile.last(10)}",
      "caller_id" => "+91#{current_user.cloud_telephony_caller_id.last(10)}"
    }
    headers = {
      'Authorization' => current_user.company.knowrality_integration.integration_key,
      'x-api-key' => current_user.company.knowrality_integration.token
    }
    response = ExotelSao.secure_post_with_headers(url, request_body, headers)
    if response["status"] == "success"
      call_log = self.call_logs.build(
        caller: 'User',
        phone_number_sid: current_user.cloud_telephony_sid&.number,
        direction: 'outgoing',
        sid: response["call_id"],
        start_time: Time.now.in_time_zone,
        to_number: self.mobile,
        from_number: current_user.mobile,
        user_id: current_user&.id,
        third_party_id: 'knowrality',
      )
      if call_log.save
        return true, "Success"
      else
        return false, call_log.errors.full_messages.join(', ')
      end
    else
      false
    end
  end

  def make_way_to_voice_call(current_user)
    begin
      radom_reference_no = SecureRandom.uuid
      url = "https://way2voice.in:444/FileApi/OBDCall?key=3646&userid=mukandan&password=mukandan@123&CallerNo=#{self.mobile.last(10)}&AgentNo=#{self.user.mobile}&refid=#{radom_reference_no}"
      status, code, response = HttpSao.secure_get(url)
      if response["status"] == "success"
        radom_reference_no = response["cdtrno"]
      end
      call_log = self.call_logs.build(
        caller: 'User',
        phone_number_sid: '07357350028',
        direction: 'outgoing',
        sid: radom_reference_no,
        start_time: Time.now.in_time_zone,
        to_number: self.mobile,
        from_number: current_user.mobile,
        user_id: current_user&.id,
        third_party_id: 'way2voice'
      )
      if call_log.save
        return true, "Success"
      else
        return false, call_log.errors.full_messages.join(', ')
      end
    rescue => e
      false
    end
  end

  def make_czentrixcloud_call(current_user)
    begin
      url = "https://admin.c-zentrixcloud.com/apps/appsHandler.php?transaction_id=CTI_DIAL&agent_id=#{current_user.agent_id}&phone_num=#{self.mobile&.last(10)}&resFormat=3&uniqueid=#{self.id}"
      response = McubeSao.secure_get(url)
      response = response["response"] rescue ""
      if response.present?
        return true if response["status"] == "SUCCESS"
      end
      return false
    rescue => e
      false
    end
  end

  def make_teleteemtech_call(current_user)
    url = "https://tele.teemtech.in/api/tfapi/agentoutgoingcall"
    request_body = {
      authkey: current_user.company.teleteemtech_integration.integration_key,
      agentid: current_user.ivr_id,
      mobile: self.mobile
    }
    begin
      response = ExotelSao.secure_post(url, request_body)
      if response['id'].present?
        call_log = self.call_logs.build(
          caller: 'User',
          phone_number_sid: current_user.cloud_telephony_no.last(10),
          direction: 'outgoing',
          sid: response["id"],
          start_time: Time.now.in_time_zone,
          to_number: self.mobile,
          from_number: current_user.mobile,
          user_id: current_user&.id,
          third_party_id: 'teleteemtech'
        )
        if call_log.save
          return true, "Success"
        else
          return false, call_log.errors.full_messages.join(', ')
        end
      end
      return false
    rescue => e
      false
    end
  end

  def make_tatatele_call(current_user)
    begin
      url = "https://api-smartflo.tatateleservices.com/v1/click_to_call"
      request_body = {
        "agent_number"=> "+91#{current_user.mobile.last(10)}",
        "destination_number" => "+91#{self.mobile.last(10)}",
        "caller_id" => "+91#{current_user.cloud_telephony_no.last(10)}",
        "get_call_id" => 1
      }
      headers = {
        'Authorization' => current_user.company.tatatele_integration.integration_key
      }
      response = ExotelSao.secure_post_with_auth_headers_response(url, request_body, headers)
      if response.present? && response["success"]
        call_log = self.call_logs.build(
          caller: 'User',
          phone_number_sid: current_user.cloud_telephony_no.last(10),
          direction: 'outgoing',
          sid: response["call_id"],
          start_time: Time.now.in_time_zone,
          to_number: self.mobile,
          from_number: current_user.mobile,
          user_id: current_user&.id,
          third_party_id: 'tatatele'
        )
        if call_log.save
          return true, "Success"
        else
          return false, call_log.errors.full_messages.join(', ')
        end
      end
      return false
    rescue => e
      false
    end
  end

  def make_slashrtc_call(current_user)
    begin
      domain_name=current_user.company.slashrtc_integration.domain
      url = "https://#{domain_name}.slashrtc.in/slashRtc/callingApis/clicktoDial"
      request_body = {
        "agenTptId"=> "#{current_user.email}",
        "customerNumber" => "#{self.mobile.last(10)}",
        "tokenId" => current_user.company.slashrtc_integration.integration_key
      }
      response = ExotelSao.secure_post_with_auth_headers_response(url, request_body, {})
      if response.present? && response["OUTPUT"] == "CLICK_TO_CALL_GENERATED"
        call_log = self.call_logs.build(
          caller: 'User',
          phone_number_sid: current_user.cloud_telephony_no.last(10),
          direction: 'outgoing',
          sid: response["JSON_INFO"],
          start_time: Time.now.in_time_zone,
          to_number: self.mobile,
          from_number: current_user.mobile,
          user_id: current_user&.id,
          third_party_id: 'slashrtc'
        )
        if call_log.save
          return true, "Success"
        else
          return false, call_log.errors.full_messages.join(', ')
        end
      end
      return false
    rescue => e
      false
    end
  end

  def make_callerdesk_call(current_user)
    begin
      api_key = current_user.company.callerdesk_integration.integration_key
      url = "https://app.callerdesk.io/api/click_to_call_v2?calling_party_a=#{current_user.mobile}&calling_party_b=#{self.mobile}&deskphone=#{current_user.cloud_telephony_sid&.number}&authcode=#{api_key}&call_from_did=1"
      status, code, response = HttpSao.secure_get(url)
      if status && code == "200"
        call_log = self.call_logs.build(
          caller: 'User',
          phone_number_sid: current_user.cloud_telephony_sid&.number,
          direction: 'outgoing',
          sid: response["campid"],
          start_time: Time.now.in_time_zone,
          to_number: self.mobile,
          from_number: current_user.mobile,
          user_id: current_user&.id,
          third_party_id: 'callerdesk'
        )
        if call_log.save
          return true, "Success"
        else
          return false, call_log.errors.full_messages.join(', ')
        end
      end
      return false
    rescue => e
      false
    end
  end

  def magic_field_values
    field_attributes = []
    self.company.magic_fields.each do |field|
      field_attributes.push({
        key: "#{field.name}",
        value: self.send("#{field.name}"),
        datatype: field.datatype,
        label_name: field.pretty_name,
        is_select_list: field.is_select_list,
        items: field.items
      })
    end
    field_attributes
  end

  def is_repeated_call?
    self.call_logs.answered.count > 1
  end

  def delete_marked_for_deletion
    if self.should_delete
      self.should_delete = false
      self.destroy
    end
    return true
  end

  def ctoc_enabled
    current_user = Lead.current_user
    if current_user.present?
      self.is_phone_number_valid? && current_user.click_to_call_enabled? && current_user.sid_active? && current_user.mobile.present?
    end
  end

  def selectable_company_stages
    if self.persisted?
      if self.company.company_stage_statuses.present?
        self.company.company_stages.joins(:company_stage_statuses).where(company_stage_statuses: {status_id: self.status_id})
      else
        self.company.company_stages
      end
    else
      self.company.company_stages
    end
  end

  def generate_uniq_ssid
    uuid = SecureRandom.uuid
    return uuid if Leads::CallLog.find_by_sid(uuid).blank?
    return self.generate_uniq_ssid
  end

  private
    def generate_uniq_lead_no
      string = "LEA#{rand.to_s[2..9]}"
      return string if check_uniqueness_of_lead_no string
      return generate_uniq_lead_no
    end


    def check_uniqueness_of_lead_no enquiry_no
      return !self.class.find_by_lead_no(enquiry_no).present?
    end

    def delete_audit_logs
      audits.destroy_all
    end

    def set_executive
      company = self.company.reload
      if company.round_robin_enabled?
        if self.user.blank? || (self.user.is_super? && (self.enable_admin_assign == "false" || self.enable_admin_assign.nil?))
          if company.project_wise_round_robin
            project_round_robin_ids = self.project.dyn_assign_user_ids
            if company.closing_executive_round_robin
              user_ids = company.users.round_robin_users.where(id: project_round_robin_ids).ids
            else
              user_ids = company.users.round_robin_users.where(id: project_round_robin_ids).ids
            end
            lead_user_id = company.leads.where(project_id: self.project_id).last&.user_id
          elsif company.secondary_level_round_robin
            ss_level_ids = company.round_robin_settings.where(project_id: self.project_id, source_id: self.source_id, sub_source_id: self.enquiry_sub_source_id).pluck(:user_id).uniq
            if company.closing_executive_round_robin
              user_ids = company.users.round_robin_users.not_meeting_executies.where(id: ss_level_ids).ids
            else
              user_ids = company.users.round_robin_users.where(id: ss_level_ids).ids
            end
            lead_user_id = company.leads.where(project_id: self.project_id, source_id: self.source_id, enquiry_sub_source_id: self.enquiry_sub_source_id).last&.user_id
          else
            lead_user_id = company.leads.last&.user_id
            if company.closing_executive_round_robin
              user_ids = company.users.round_robin_users.not_meeting_executies.ids
            else
              user_ids = company.users.round_robin_users.ids
            end
          end
          if user_ids.include? lead_user_id
            user_ids.each_with_index do |u, index|
              if(lead_user_id == u)
                if(index == user_ids.size - 1)
                  self.user_id = user_ids[0]
                else
                  self.user_id = user_ids[index+1]
                  break
                end
              end
            end
          else
            self.user_id = user_ids[0] || company.users.active.superadmins.first.id
          end
        end
      else
        self.user_id = company.users.active.superadmins.first.id if self.user_id.blank?
      end
    end

    def set_closing_excutive
      if self.closing_executive.blank? && company.setting.present? && company.closing_executive_round_robin && self.company.closing_executive_trigger_statuses.present? && self.changes.present? && self.changes.include?('status_id') && self.company.closing_executive_trigger_statuses.include?(self.changes["status_id"][1]&.to_s)
        if company.project_wise_round_robin
          project_round_robin_ids = self.project.dyn_assign_closing_executive_ids
          closing_executive_ids = company.users.meeting_executives.round_robin_closing_executives.where(id: project_round_robin_ids).ids
          lead_closing_executive = company.leads.where.not(id: self.id).where(project_id: self.project_id).last&.closing_executive
        else
          lead_closing_executive = company.leads.where.not(id: self.id).last&.closing_executive
          closing_executive_ids = company.users.meeting_executives.round_robin_closing_executives.ids
        end
        if closing_executive_ids.include? lead_closing_executive
          closing_executive_ids.each_with_index do |u, index|
            if(lead_closing_executive == u)
              if(index == closing_executive_ids.size - 1)
                self.closing_executive = closing_executive_ids[0]
              else
                self.closing_executive = closing_executive_ids[index+1]
                break
              end
            end
          end
        else
          self.closing_executive = closing_executive_ids[0]
        end
      end
    end
end
