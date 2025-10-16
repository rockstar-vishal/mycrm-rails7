class SystemSms < ActiveRecord::Base
  validates :mobile, :text, presence: true
  belongs_to :company
  belongs_to :user
  belongs_to :messageable, polymorphic: true
  scope :successful, -> { where(:sent=>true) }
  scope :of_leads, -> { where(:messageable_type=>"Lead") }

  after_commit :send_sms, on: :create

  def send_sms
    if self.template_id.present? && self.is_vf_sms
      Resque.enqueue(ProcessValueFirstSms, self.id)
    elsif self.company.mobicomm_sms_service_enabled
      Resque.enqueue(LeadRegistration, self.id)
    elsif self.company.exotel_sms_integration_enabled
      Resque.enqueue(ExotelSmsService, self.id)
    elsif self.company.sms360_enabled
      Resque.enqueue(ProcessSmsMarketing, self.id)
    elsif self.company.my_sms_shop_enabled
      Resque.enqueue(ProcessMyShopSms, self.id)
    elsif self.company.pg_sms_api_enabled
      Resque.enqueue(PgApiService, self.id)
    elsif self.company.template_flag_name == "amruttara"
      Resque.enqueue(ProcessAmruttaraSms, self.id)
    elsif self.company.template_flag_name == "ashapura"
      Resque.enqueue(ProcessAshpuraSms, self.id)
    elsif self.company.template_flag_name == "house"
      Resque.enqueue(ProcessHouseSms, self.id)
    else
      Resque.enqueue(ProcessSystemSms, self.id)
    end
  end
end
