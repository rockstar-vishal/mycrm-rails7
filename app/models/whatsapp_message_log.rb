class WhatsappMessageLog < ActiveRecord::Base
	belongs_to :lead

  enum status: { success: 0, failed: 1 }

  validates :campaign_name, :destination, presence: true
  
end
