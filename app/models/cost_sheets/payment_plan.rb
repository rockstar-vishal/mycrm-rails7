class CostSheets::PaymentPlan < ActiveRecord::Base
  belongs_to :cost_sheet
end
