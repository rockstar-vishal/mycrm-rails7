class Leads::Visit < ActiveRecord::Base

  belongs_to :lead
  belongs_to :user, optional: true
  belongs_to :source, optional: true
  has_many :visits_projects, class_name: 'Leads::VisitsProject'
  has_many :projects, class_name: '::Project', through: :visits_projects
  validates :date, presence: true
  enum status_id:{
    "Hot": 1,
    "Warm": 2,
    "Cold": 3,
    "Visit on Site": 4,
    "Outbound Meeting": 5,
    "Online Meeting": 6
  }

  has_attached_file :site_visit_form

  validates_attachment_content_type  :site_visit_form,
                        content_type: ['application/pdf', 'application/msword', 'image/jpeg', 'image/png', 'application/vnd.ms-excel',
                          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'],
                        size: { in: 0..2.megabytes }
  BANK_NAMES = ["Axis Bank","Bank of Baroda", "Citi Bank", "City Union Bank","Indian Bank", "Indian Overseas Bank","ICICI", "HDFC","Punjab National Bank","State Bank of India"]
  after_create :set_lead_revisit
  after_commit :send_sv_done_notification, on: :create
  validate :check_postpone_date

  scope :executed, -> { where(:is_visit_executed=>true) }

  delegate :name, to: :user, allow_nil: true, prefix: true


  acts_as_api

  api_accessible :sv_form_print_format do |template|
    template.add lambda {|l| l.date}, as: :visit_date
  end


  def check_postpone_date
    unless self.new_record?
      company = self.lead.company
      if company.setting.present? && company.enable_advance_visits
        if self.is_postponed && self.changes.present? && self.changes["is_postponed"].present?
          if self.changes.present? && !self.changes["date"].present?
            errors.add(:date, 'Add postponed date')
          end
        end
      end
    end
  end

  def file_url
    if self.site_visit_form.present?
      self.site_visit_form.url
    end
  end

  def set_lead_revisit
    if self.lead.visits.executed.count > 1 && self.is_visit_executed
      unless self.lead.revisit
        self.lead.update(revisit: true)
      end
    end
  end

  def send_sv_done_notification
    company = self.lead.company
    if company.setting.present? && company.enable_nextel_whatsapp_triggers 
      Resque.enqueue(::SendNextelSiteVisitDoneNotification, self.lead.id)
    elsif company.whatsapp_integration.present? && company.whatsapp_integration.integration_key.present? && company.whatsapp_integration.vendor_name.present? && lead.visits.count == 1
      kclass = "Process#{company.whatsapp_integration.vendor_name.capitalize}Notifications".constantize
      Resque.enqueue(kclass, self.lead.id)
    elsif company.whatsapp_integration.present? && company.whatsapp_integration.integration_key.present? && company.whatsapp_integration.user_name == "GBK Group"
      time = Time.now.strftime("%d-%B-%Y, %H:%M %p")
      Resque.enqueue(::ProcessGbkgroupWhatsappTrigger, self.lead.id, time, 'visit_done')
    end
  end
end
