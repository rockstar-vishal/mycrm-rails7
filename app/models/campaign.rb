class Campaign < ActiveRecord::Base
	belongs_to :company
	belongs_to :source
	validates :title, :start_date, :end_date, :budget, :source_id, presence: true

  has_many :projects, through: :campaigns_projects
  has_many :campaigns_projects, class_name: '::CampaignsProject'
  has_many :spends, :class_name=>"::Campaigns::Spend", dependent: :destroy

  delegate :name, to: :source, prefix: true, allow_nil: true

  attr_accessor :targeted_ad_spend, :actual_ad_spend, :actual_leads, :actual_ql, 
	              :actual_sv, :actual_cpl, :actual_cpql, :actual_cpsv, :cpb, 
	              :inquiry_to_ql, :qualified_to_sv, :inquiry_to_sv,
	              :sv_to_booking, :inquiry_to_booking, :targeted_cpl,
	              :targeted_cpql, :targeted_cpsv, :booking_count,
	              :targeted_site_visits, :actual_ad_spend

 	def calculate_metrics(leads)
    self.targeted_ad_spend = budget.to_f
    self.actual_ad_spend = spends.sum(:spend_amount)
    campaign_leads = leads.where(source: source, created_at: start_date.beginning_of_day..end_date.end_of_day)
    campaign_qualified_leads = campaign_leads.qualified
    self.actual_leads = campaign_leads.count
    self.actual_ql = campaign_qualified_leads.count
    project_ids = projects.pluck(:id)
    self.booking_count = campaign_leads.where(status_id: company.booking_done_id, project_id: project_ids).count

    self.targeted_cpl = targeted_leads.to_f.nonzero? ? (targeted_ad_spend / targeted_leads.to_f).round(2) : 0
    self.actual_cpl = actual_leads.nonzero? ? (actual_ad_spend / actual_leads).round(2) : 0

    self.targeted_cpql = targeted_ql.to_f.nonzero? ? (targeted_ad_spend / targeted_ql.to_f).round(2) : 0
    self.actual_cpql = actual_ql.nonzero? ? (actual_ad_spend / actual_ql).round(2) : 0

    self.actual_sv = campaign_qualified_leads.joins(:visits).count

    self.targeted_cpsv = targeted_sv.to_f.nonzero? ? (targeted_ad_spend / targeted_sv.to_f).round(2) : 0
    self.actual_cpsv = actual_sv.nonzero? ? (actual_ad_spend / actual_sv).round(2) : 0
    self.cpb = targeted_bookings.to_f.nonzero? ? actual_ad_spend / booking_count.to_f : 0

    self.inquiry_to_ql = actual_leads.nonzero? ? actual_ql.to_f / actual_leads : 0
    self.qualified_to_sv = actual_ql.nonzero? ? actual_sv.to_f / actual_ql : 0
    self.inquiry_to_sv = actual_leads.nonzero? ? actual_sv.to_f / actual_leads : 0
    self.sv_to_booking = actual_sv.nonzero? ? booking_count.to_f / actual_sv : 0
    self.inquiry_to_booking = actual_leads.nonzero? ? booking_count.to_f / actual_leads : 0
  end
end
