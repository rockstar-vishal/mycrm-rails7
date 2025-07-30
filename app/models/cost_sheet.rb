class CostSheet < ActiveRecord::Base
  belongs_to :company
  belongs_to :user
  has_many :other_items, :class_name=>"::CostSheets::OtherItem", dependent: :destroy

  validates :project_name, :building_name, :topology, :flat_no, :total_cost, presence: true
  validate :agreement_total_must_not_exceed_total_cost
  after_save :convert_percent_to_amount
  accepts_nested_attributes_for :other_items, reject_if: :all_blank, allow_destroy: true

  def convert_percent_to_amount
    percentage_slab=self.other_items.where.not(percentage: nil)
    total_amount = self.total_cost.to_i
    percentage_slab.each do |slab|
      amount = ((slab.percentage/100.0)*(total_amount)).round()
      percentage = nil
      slab.update_attributes(amount: amount, percentage: percentage)
    end
  end

  class << self
    def basic_search(search_string)
      all.where("project_name ILIKE :term OR building_name ILIKE :term OR topology ILIKE :term OR flat_no ILIKE :term", :term=>"%#{search_string}%")
    end
  end

  private

  def agreement_total_must_not_exceed_total_cost
    manual_total = total_cost.to_i
    agreement_total = 0

    other_items.each do |item|
      next if item._destroy
      next unless item.cost_type_id.to_s == "Agreement"

      if item.percentage.present?
        percentage_amount = ((item.percentage.to_f / 100.0) * manual_total).round
        agreement_total += percentage_amount
      elsif item.amount.present?
        agreement_total += item.amount.to_i
      end
    end
    if agreement_total > manual_total
      diff = agreement_total - manual_total
      percent_over = ((diff.to_f / manual_total) * 100).round(2)
      errors.add(:base, "Agreement total ₹#{agreement_total} exceeds total cost ₹#{manual_total} by ₹#{diff} (#{percent_over}%)")
    end
  end
end
