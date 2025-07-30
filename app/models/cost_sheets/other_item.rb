class CostSheets::OtherItem < ActiveRecord::Base
  belongs_to :cost_sheet

  enum slab_operator: {
    'Add': 1,
    'Subtract': 2
  }

  enum cost_type_id:{
    "Agreement": 1,
    "Non-Agreement": 2,
    "NTND": 3
  }

  validates :name, :section_name, presence: true
  validate :amount_or_percent_present

  scope :deduction_slabs, -> {where(slab_operator: 2)}
  scope :additional_slabs, -> {where(slab_operator: 1)}

  def amount_or_percent_present
    if %w(amount percentage).all?{|attr| self[attr].blank?}
      self.errors.add(:base, "Amount or Percentage should be present")
      return false
    end
    if %w(amount percentage).all?{|attr| self[attr].present?}
      self.errors.add :base, "Either Amount or Percentage should be present"
      return false
    end
  end
end
