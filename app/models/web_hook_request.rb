class WebHookRequest < ActiveRecord::Base

  validates :request_uuid, :secondary_request_uuid, presence: true

  other_data_field = [
    :template_id,
    :conversation_id,
    :wa_id,
    :ticket_id,
    :request_completed,
  ]

  def default_fields_values
    self.other_data || {}
  end

  other_data_field.each do |method|
    define_method("#{method}=") do |val|
      self.other_data_will_change!
      self.other_data = (self.other_data || {}).merge!({"#{method}" => val})
    end
    define_method("#{method}") do
      default_fields_values.dig("#{method}")
    end
  end

end
