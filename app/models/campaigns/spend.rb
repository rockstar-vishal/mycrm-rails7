class Campaigns::Spend < ActiveRecord::Base
	belongs_to :campaign
	belongs_to :company
end
