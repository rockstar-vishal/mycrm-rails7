class Otp < ActiveRecord::Base

  TYPES = ["PHONE", "EMAIL"]

  belongs_to :user
  belongs_to :company
  belongs_to :resource, polymorphic: true
  validates :validation_type, :validatable_data, :code, presence: true
  validates :code, uniqueness: true

  enum event_type: {sv_visit: 0}

  before_validation :set_code, on: :create

  scope :for_phones, -> { where(validation_type: "PHONE") }
  scope :for_emails, -> { where(validation_type: "EMAIL") }

  scope :unused, -> { where(used: false) }
  scope :gen_in_last_20_minutes, -> {where("otps.created_at >= ?", (Time.zone.now - 20.minutes))}

  after_commit :send_sms_alert, on: :create

  def is_phone_otp?
    return self.validation_type == "PHONE"
  end

  def is_email_otp?
    return self.validation_type == "EMAIL"
  end

  def send_sms_alert
    if self.is_phone_otp?
      if self.company.sv_form.present? && self.company.sv_form.enable_otp
        SmsService.send_sv_otp(self)
      elsif self.company.sms_integration.url.present? && self.company.sms_integration.url == "http://www.k3digitalmedia.co.in"
        SmsService.send_sonam_otp(self)
      elsif self.company.sms_integration.url.present? && self.company.sms_integration.url == "http://login.bulksmsservice.net.in"
        SmsService.send_ravima_otp(self)
      else
        SmsService.send_otp(self)
      end
    end
  end

  def use
    if self.update_attributes(:used=>true)
      return true
    else
      return false
    end
  end

  def set_code
    self.code = generate_uniq_code
  end

  protected

  def generate_uniq_code
    code = rand.to_s[2..7]
    return code if Otp.find_by_code(code).blank?
    return self.generate_uniq_code
  end

end
