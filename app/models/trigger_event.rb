class TriggerEvent < ActiveRecord::Base

  validates :object_entity, :receiver_type, :trigger_type, :template_id, presence: true
  validates :to_status, presence: true, if: Proc.new { |t| t.trigger_hook_type == "Status" }
  belongs_to :communication_template
  has_many :communication_attributes, :class_name=> "::CommunicationAttribute", dependent: :destroy

  accepts_nested_attributes_for :communication_attributes, reject_if: :all_blank, allow_destroy: true

  scope :to_lead, -> { where(receiver_type: 'Lead') }
  scope :to_user, -> { where(receiver_type: 'User') }
  scope :to_lead_create_event, -> { where(receiver_type: 'Lead', trigger_type: 'On Create') }
  scope :to_lead_update_event, -> { where(receiver_type: 'Lead', trigger_type: 'On Update') }
  scope :to_user_create_event, -> { where(receiver_type: 'User', trigger_type: 'On Create') }
  scope :to_user_update_event, -> { where(receiver_type: 'User', trigger_type: 'On Update') }
end