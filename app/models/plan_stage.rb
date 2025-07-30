class PlanStage < ActiveRecord::Base
  belongs_to :payment_plan
  validates :title, :percentage, presence: true
end
