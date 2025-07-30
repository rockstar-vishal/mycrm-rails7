class CompanyStatus < ActiveRecord::Base
  belongs_to :company
  belongs_to :status
  default_scope { order(order: :asc).order(created_at: :asc) }
end
