class CloudTelephonySid < ActiveRecord::Base
  enum vendor:{
    "knowlarities": 1,
    "tatatele": 2,
    "slashrtc": 3,
    "callerdesk": 4,
    "twispire": 5,
    "teleteemtech": 6,
    "ivrmanager": 7
  }

  DEFAULT_SOURCE = 2

  validates :number, presence: true, uniqueness: true

  belongs_to :company

  scope :for_knowrality, -> {where(vendor: 1)}
  scope :for_knowrality, -> {where(vendor: 2)}
  scope :for_slashrtc, -> {where(vendor: 3)}
  scope :active, -> { where(is_active: true) }

  before_save :set_caller_id


  def set_caller_id
    self.caller_id = self.number
  end
end
