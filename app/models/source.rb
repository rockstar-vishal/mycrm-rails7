class Source < ActiveRecord::Base

  include AppSharable

  scope :active, -> { where(:active=>true) }
  scope :cp_sources, -> { active.where(:is_cp=>true) }
  scope :digital_sources, -> { active.where(:is_digital=>true) }
  scope :referal_sources, -> { active.where(:is_reference=>true) }
  has_many :leads
  has_many :sub_sources
  has_many :users_sources, class_name: 'UsersSource'
  has_many :accessible_users, through: :users_sources, class_name: 'User', source: :user
  validates :name, presence: true, uniqueness: true
  before_destroy :check_leads

  WEBSITE = 1
  INCOMING_CALL = 2
  FACEBOOK = 14
  HOUSING = 18
  MAGICBRICKS = 4
  NINE_NINE_ACRES = 3
  GOOGLE_ADS = 15
  CHANNEL_PARTNER = 30

  def check_leads
    if self.leads.present?
      self.errors.add(:base, "This enquiry source is in use")
      return false
    end
  end

  def website?
    self.id == WEBSITE
  end

  def incoming_call?
    self.id == INCOMING_CALL
  end

end
