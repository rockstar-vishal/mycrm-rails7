class Broker < ActiveRecord::Base
  include AppSharable
  include PostsaleIntegrationApi

  attr_accessor :enable_partner_integration

  belongs_to :company
  has_many :leads, dependent: :restrict_with_error
  default_scope { order(created_at: :asc) }
  belongs_to :rm, class_name: "::User", foreign_key: :rm_id, optional: true

  has_attached_file :rera_document,
                    path: ":rails_root/public/system/:attachment/:id/:style/:filename",
                    url: "/system/:attachment/:id/:style/:filename"
  validates_attachment :rera_document, 
                        content_type: { :content_type => %w( application/pdf application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document) }

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
  validates :mobile, length: {maximum: 15}, presence: true
  validates :name, presence: true
  validates_uniqueness_of :email, :rera_number, :cp_code, { scope: :company_id,
    message: "Should be unique", allow_nil: true }
  validate :validate_broker_required_fields
  validate :mobile_uniqueness
  RERA_STATUS=["Yes", "No", "Work In Progress"]
  after_commit :broker_integration_to_postsale, on: :create, if: :enable_broker_integration?
  after_commit :broker_integration_to_partner_crm, on: :create, if: :enable_partner_crm_integration?

  def enable_broker_integration?
    self.company.setting.present? && self.company.setting.biz_integration_enable && self.company.setting.broker_integration_enable
  end

  def enable_partner_crm_integration?
    self.company.setting.present? && self.company.setting.enable_partner_crm_integration && self.company.partner_crm_url.present? && self.enable_partner_integration == 'true'
  end

  def validate_broker_required_fields
    if self.company.broker_configuration.present? && self.company.broker_configuration_required_fields.reject(&:empty?).present?
      self.company.broker_configuration_required_fields.reject(&:empty?).each do |field|
        if self.respond_to?(("#{field}".to_sym))
          if self.send("#{field}".to_sym).blank?
            self.errors.add(:base, "#{field.split('_').map(&:capitalize).join(' ')} cant be blank")
          end
        end
      end
    end
  end

  def mobile_uniqueness
    brokers = self.company.brokers.where.not(id: self.id).where("RIGHT(replace(mobile, ' ', ''), 10) LIKE ?","#{self.mobile.last(10)}")
    if brokers.present?
      self.errors.add(:base, "Mobile No. should be unique")
    end
  end

  class << self

    def basic_search(search_string)
      all.where("name ILIKE ? OR firm_name ILIKE ? OR mobile ILIKE ? OR email ILIKE ? OR rera_number ILIKE ? OR locality ILIKE ? OR cp_code ILIKE ?", "%#{search_string}%", "%#{search_string}%", "%#{search_string}%", "%#{search_string}%", "%#{search_string}%", "%#{search_string}%","%#{search_string}%")
    end

    def to_csv(options = {}, exporting_user, ip_address, brokers_count)
      exporting_user.company.export_logs.create(user_id: exporting_user.id, ip_address: ip_address, count: brokers_count)
      CSV.generate(options) do |csv|
        exportable_fields = ['CP Uuid','Name', 'Mobile', 'Email', 'Firm Name', 'Rera Number', 'RM','Locality', 'Address', 'Other Contacts','Rera Status', 'CP Code']
        csv << exportable_fields
        all.includes(:rm).each do |broker|
          this_exportable_fields = [broker.uuid, broker.name, broker.mobile, broker.email, broker.firm_name, broker.rera_number, (broker.rm.name rescue '-'), broker.locality, broker.address, broker.other_contacts, broker.rera_status, broker.cp_code]
          csv << this_exportable_fields
        end
      end
    end

  end

  def name_with_firm_name
    if self.firm_name.present?
      return "#{self.name} - #{self.firm_name}"
    else
      return "#{self.name}"
    end
  end

end
