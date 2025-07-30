class CommunicationTemplate < ActiveRecord::Base
  validates :template_name, :notification_type, presence: true
  validates :company_id, presence: true, uniqueness: true
  belongs_to :company
  has_many :trigger_events, :class_name=> "::TriggerEvent", dependent: :destroy

  accepts_nested_attributes_for :trigger_events, reject_if: :all_blank, allow_destroy: true

  scope :for_sms, -> { where(notification_type: 'SMS') }
  scope :for_wp, -> { where(notification_type: 'WhatsApp') }

  class << self
    def advance_search(search_params)
      templates = all

      if search_params[:notification_types].present?
        templates = templates.where(notification_type: search_params[:notification_types])
      end
      if search_params[:company_ids].present?
        templates = templates.where(company_id: search_params[:company_ids])
      end

      return templates
    end
  end
end
