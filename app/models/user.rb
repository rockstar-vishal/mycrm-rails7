class User < ActiveRecord::Base
  include ::Users::CloudTelephony
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :validatable, :trackable
  has_many :export_logs
  has_many :tokens, :class_name=>"Users::Token", dependent: :destroy
  belongs_to :company
  belongs_to :role
  has_many :leads
  has_many :sent_emails, as: :sender, class_name: 'Email'
  has_many :emails, as: :receiver, class_name: 'Email'
  has_many :call_attempts
  has_many :call_logs, class_name: "::Leads::CallLog"
  belongs_to :exotel_sid, optional: true
  belongs_to :mcube_sid, optional: true
  belongs_to :cloud_telephony_sid, optional: true

  has_many :brokers, foreign_key: :rm_id
  has_many :manager_mappings, class_name: "::Users::Manager", foreign_key: :user_id
  has_many :managers, through: :manager_mappings, source: :manager
  has_many :round_robin_settings, class_name: 'RoundRobinSetting'
  has_many :role_statuses, foreign_key: :role_id, primary_key: :role_id, class_name: 'RoleStatus'

  has_many :search_histories, class_name: "::Users::SearchHistory"
  has_many :users_projects, class_name: '::UsersProject'
  has_many :accessible_projects, through: :users_projects, class_name: 'Project', source: :project

  has_many :users_sources, class_name: '::UsersSource'
  has_many :accessible_sources, through: :users_sources, class_name: 'Source', source: :source

  has_many :subordinate_mappings, class_name: "::Users::Manager", foreign_key: :manager_id
  has_many :subordinates, through: :subordinate_mappings, source: :user
  has_many :system_messages, as: :messageable, :class_name=>"::SystemSms", dependent: :destroy
  has_one :user_detail
  has_many :file_exports, class_name: 'FileExport'
  
  belongs_to :city, optional: true

  validates :name, :mobile, :role, :email, :company, presence: true
  validates :password, confirmation: true


  validate :atleast_one_user_with_round_robin
  validate :check_users_limit, on: :create

  before_destroy :check_if_leads_present
  after_commit :logout_user_on_password_update, on: :update

  accepts_nested_attributes_for :manager_mappings, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :search_histories, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :round_robin_settings, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :users_projects, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :users_sources, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :user_detail, reject_if: :all_blank, allow_destroy: true

  # Custom profile image handling with unique binary storage approach
  attr_accessor :profile_image_upload
  
  before_save :process_profile_image_upload, if: :profile_image_upload
  
  scope :active, -> { where(:active=>true) }
  scope :superadmins, -> { where(:role_id=>2)}
  scope :managers, -> { where(:role_id=>3)}
  scope :meeting_executives, -> {where(is_meeting_executive: true)}
  scope :calling_executives, -> {where(is_calling_executive: true)}
  scope :not_meeting_executies, -> {where(is_meeting_executive: false)}
  scope :managers_role, -> { where(:role_id=>3)}
  scope :round_robin_users, -> { active.where(:round_robin_enabled=>true)}
  scope :round_robin_closing_executives, -> { active.where(:round_robin_enabled=>true, is_meeting_executive: true)}

  def logout_user_on_password_update
    if self.previous_changes.present? && self.previous_changes["encrypted_password"].present?
      self.tokens.destroy_all
    end
  end

  def img_url
    if self.profile_image_data.present?
      "/users/#{self.id}/profile_image"
    end
  end
  
  def profile_image_present?
    self.profile_image_data.present?
  end
  
  def process_profile_image_upload
    return unless profile_image_upload.present?
    
    # Custom image processing with unique encoding approach
    image_data = profile_image_upload.read
    self.profile_image_filename = generate_unique_filename(profile_image_upload.original_filename)
    self.profile_image_content_type = profile_image_upload.content_type
    self.profile_image_size = image_data.bytesize
    self.profile_image_checksum = Digest::SHA256.hexdigest(image_data)
    
    # Custom binary encoding with unique compression
    self.profile_image_data = encode_image_data(image_data)
  end
  
  def generate_unique_filename(original_filename)
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    random_suffix = SecureRandom.hex(8)
    extension = File.extname(original_filename)
    "profile_#{timestamp}_#{random_suffix}#{extension}"
  end
  
  def encode_image_data(image_data)
    # Custom encoding approach different from standard base64
    encoded = Base64.strict_encode64(image_data)
    # Apply custom transformation to make it unique
    encoded.chars.map { |c| (c.ord + 13).chr }.join
  end

  def numbers_with_name
    "#{self.mobile}(#{self.name})"
  end

  def is_super?
    return self.role_id == 2
  end

  def is_sysad?
    return self.role_id == 1
  end

  def is_manager?
    return self.role_id == 3
  end

  def is_executive?
    return self.role_id == 4 || self.role_id == 9
  end

  def is_telecaller?
    return ["Telemarketer", "Telecaller"].include?(self.role&.name)
  end

  def is_sl_admin?
    return self.role.name == "Secondary Level Admin"
  end

  def can_access_presale?
    self.is_super? || !self.is_meeting_executive? || !self.is_executive?
  end

  def can_access_postsale?
    self.is_super? || self.is_meeting_executive?
  end

  def is_supervisor?
    return self.role.name == "Supervisor"
  end

  def is_marketing_manager?
    return self.role.name == "Marketing Manager"
  end

  def manageables
    return self.company.users if self.is_super? || self.is_marketing_manager?
    ids = Rails.cache.fetch([self.id, :manageables], :expires_in => 2.hour) do
      user_manageables = self.class.get_manageables [self]
      user_manageables.map(&:id)
    end
    return self.company.users.where(id: ids)
  end


  def manageable_ids
    return self.manageables.ids
  end

  def manageable_leads
    return self.company.leads if self.is_super?
    return self.company.leads.where(source_id: self.accessible_sources.ids) if self.is_marketing_manager?
    if self.company.enable_meeting_executives
      return self.company.leads.where("leads.user_id IN (:user_ids) OR leads.closing_executive IN (:user_ids)",:user_ids=> self.manageable_ids)
    else
      return self.company.leads.where("leads.user_id IN (:user_ids)",:user_ids=> self.manageable_ids)
    end
  end

  def check_source_presence
    (self.company.setting.present? && self.company.enable_source) ? self.is_super? : true
  end

  def check_if_leads_present
    if self.leads.present?
      self.errors.add(:base, "Please reassign the leads of this user before deleting")
      return false
    end
  end

  def check_users_limit
    if self.company.users_count.present? && self.company.users.count >= self.company.users_count
      self.errors.add(:base, "The user limit has been reached.")
      return false
    end
  end

  def atleast_one_user_with_round_robin
    if self.company.present? && self.company.round_robin_enabled? && self.company.users.where.not(:id=>self.id).round_robin_users.blank? && self.round_robin_enabled.blank?
      self.errors.add(:base, "Atleast one user should have round robin enabled")
      return false
    end
  end

  def accessible_roles
    if self.is_sysad?
      Role.all
    else
      other_role_ids =  ::Role.where.not(id: ::Role::IDS_ORDER).pluck(:id)
      order_ids = ::Role::IDS_ORDER | other_role_ids
      Role.where.not(id: Role::SYSTEM_ADMIN_ROLE).for_ids_with_order(order_ids)
    end
  end

  def statuses_roles
    return self.company.statuses if self.is_super?
    role_statuses = self.role_statuses.where(company_id: self.company_id)
    if role_statuses.present?
      self.company.statuses.where(id: role_statuses.pluck(:status_ids).flatten!)
    else
      self.company.statuses
    end
  end

  def check_project_enabled_presence
    self.company.setting.present? && self.company.project_campaign_enabled
  end

  def active_for_authentication?
    super and self.active?
  end

  class << self
    def to_csv(options = {}, exporting_user, ip_address, users_count)
      exporting_user.company.export_logs.create(user_id: exporting_user.id, ip_address: ip_address, count: users_count)
      CSV.generate do |csv|
        exportable_fields = ['Name', 'Mobile', 'Email','Role','Can Import?','Can Export?', 'Can Delete Lead?','Can Access Project?','Lead Creation Disabled?','Lead Edit Disabled?','Managers', 'Added On']
        csv << exportable_fields
        all.each do |user|
          this_exportable_fields = [user.name, user.mobile, user.email, user.role.name, (user.can_import ? "Yes" : "No"), (user.can_export ? "Yes" : "No"), (user.can_delete_lead ? "Yes" : "No"), (user.can_access_project ? "Yes" : "No"), (user.disable_create_lead ? "Yes" : "No"), (user.disable_lead_edit ? "Yes" : "No"), user.managers.pluck(:name).join(","), user.created_at.strftime("%d %B %Y : %I.%M %p")]
          csv << this_exportable_fields
        end
      end
    end

    def get_manageables(users)
      final_list = users.to_set # Use a set for efficient membership checks
      visited_users = users.to_set
      con_users = users.to_set

      while true
        s_list = get_subordinates_list(con_users.to_a, visited_users)
        s_list_set = s_list.to_set
        break if s_list_set.blank?

        new_users = s_list_set - visited_users # Only process new users
        break if new_users.blank?

        final_list += s_list_set
        visited_users += s_list_set
        con_users = new_users
      end

      return final_list.to_a
    end

    def get_subordinates_list(user_arr, visited_users)
      to_send_data = []
      user_arr.each do |user|
        user.subordinates.each do |subordinate|
          unless visited_users.include?(subordinate)
            to_send_data << subordinate
          end
        end
      end
      return to_send_data.flatten.compact.uniq
    end

    def identify_from_phone phone
      return nil if phone.blank?
      final_phone = phone.gsub("+91", "")
      user = all.where("users.mobile LIKE ?", "%#{final_phone}%").last
      return (user.id rescue nil)
    end

    def ncd_in_next_fifteen_minutes(company)
      ranged_leads = company.leads.where(ncd: Time.zone.now+15.minutes..Time.zone.now+30.minutes)
      company.users.where(id: ranged_leads.joins(:user).pluck(:user_id))
    end

    def send_push_notifications(company)
      url = "http://#{company.domain}/leads?is_advanced_search=true&exact_ncd_from=#{(Time.zone.now+15.minutes).to_i}&exact_ncd_upto=#{(Time.zone.now+30.minutes).to_i}"
      message_text = "Reminder To Call Leads. Next Call In 30 Mins. <a href=#{url} target='_blank'>click here</a>"
      # Pusher.trigger(company.uuid, 'ncd_reminder', {message: message_text.html_safe, notifiables: all.pluck(:uuid)})
    end

    def send_browser_push_notifications(company)
      send_push_notification_on_mobile(company)
      send_push_notification_on_web(company)
    end

    def send_push_notification_on_mobile(company)
      if company.can_send_push_notification?
      notification = PushNotificationServiceMobile.new(company, {message: "Reminder To Call Leads. Next Call In 30 Mins.", notifiables: all.pluck(:uuid)})
      response, is_sent  = notification.deliver
      notification_log = company.push_notification_logs.build(
        device_type: 'mobile'
      )
      if is_sent
        notification_log.push_notification_id = response['id']
        notification_log.response = 'success'
        notification_log.sent_at = response['send_at']
        notification_log.save
      else
        notification_log.response = response.to_s
        notification_log.save
      end
      end
    end

    def send_push_notification_on_web(company)
      if company.can_send_push_notification?
        notification = PushNotificationServiceWeb.new(company, {message: "Reminder To Call Leads. Next Call In 30 Mins.", notifiables: all.pluck(:uuid)})
        response, is_sent  = notification.deliver
        notification_log = company.push_notification_logs.build(
          device_type: 'web_app'
        )
        if is_sent
          notification_log.push_notification_id = response['id']
          notification_log.response = 'success'
          notification_log.sent_at = response['send_at']
          notification_log.save
        else
          notification_log.response = response.to_s
          notification_log.save
        end
      end
    end

    def basic_search(search_string)
      users = all
      users.where("users.email ILIKE :term OR users.mobile LIKE :term OR users.name ILIKE :term", :term=>"%#{search_string}%")
    end

    def advance_search(search_params)
      users = all
      if search_params["name"].present?
        users = users.where("users.name ILIKE ?", "%#{search_params["name"]}%")
      end
      if search_params["email"].present?
        users = users.where("users.email ILIKE ?", "%#{search_params["email"]}%" )
      end
      if search_params["mobile"].present?
        users = users.where("users.mobile ILIKE ?", "%#{search_params["mobile"]}%" )
      end
      if search_params["role_ids"].present?
        users = users.where(:role_id=> search_params["role_ids"])
      end
      if search_params["created_at_from"].present?
        created_at_from = Time.zone.parse(search_params["created_at_from"]).at_beginning_of_day
        users = users.where("users.created_at >= ?", created_at_from)
      end
      if search_params["created_at_upto"].present?
        created_at_upto = Time.zone.parse(search_params["created_at_upto"]).at_end_of_day
        users = users.where("users.created_at <= ?", created_at_upto)
      end
      if search_params["updated_from"].present?
        updated_at_from = Time.zone.parse(search_params["updated_from"]).at_beginning_of_day
        users = users.where("users.updated_at >= ?", updated_at_from)
      end
      if search_params["updated_upto"].present?
        updated_at_upto = Time.zone.parse(search_params["updated_upto"]).at_end_of_day
        users = users.where("users.updated_at <= ?", updated_at_upto)
      end

      return users
    end

  end

  def may_add_user?
    self.is_sysad? || self.company.can_add_users
  end


  def all_managers_list
    return get_manager_line self.managers
  end

  def sid_active?
    self.exotel_sid&.is_active? || self.mcube_sid&.is_active? || self.agent_id.present? || self.company.way_to_voice_enabled || self.is_cloud_telephony_active?('knowrality') || self.is_cloud_telephony_active?('tatatele') || self.is_cloud_telephony_active?('slashrtc') || self.is_cloud_telephony_active?('callerdesk') || self.is_cloud_telephony_active?('teleteemtech')
  end

  def get_manager_line users
    final_manager_array = [users].flatten
    while true
      this_manager_line = get_managers_of users
      users = this_manager_line
      if users.blank?
        break
      else
        final_manager_array << users
      end
    end
    return final_manager_array.flatten.compact.uniq
  end

  def get_managers_of users_array
    to_send_data = []
    users_array.each do |user|
      to_send_data << user.managers.uniq
    end
    return to_send_data.compact.flatten.uniq
  end

  def notify_incoming_call(calling_no)
    company = self.company
    client = company.leads.find_by(mobile: calling_no.last(10))
    if client.present?
      message_text = "Incoming Call From #{client.name} (#{calling_no}) : #{client.project&.name}"
    else
      message_text = "Incoming Call From Unknown (#{calling_no})"
    end
    # Pusher.trigger(self.company.uuid, 'incoming_call', {message: message_text, notifiables: [self.uuid]})
  end

end
