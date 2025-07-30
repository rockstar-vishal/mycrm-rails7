class PaymentPlan < ActiveRecord::Base
  acts_as_api
  belongs_to :company
  has_many :plan_stages

  validates :title, presence: true

  accepts_nested_attributes_for :plan_stages, reject_if: :all_blank, allow_destroy: true

  api_accessible :details do |t|
    t.add :title
    t.add :stage_detail
  end

  def stage_detail
    return nil unless self.plan_stages.present?
    send_data=[]
    self.plan_stages.each do |h|
      send_data << {title: h.title, percentage: h.percentage}
    end
    return send_data
  end

  class << self

    def basic_search(search_string)
      payment_plans = all
      payment_plans.where("title ILIKE :term", :term=>"%#{search_string}%")
    end
  end
end
