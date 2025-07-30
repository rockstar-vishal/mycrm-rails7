class UserDetail < ActiveRecord::Base
  belongs_to :user

  other_data_field = [
    :earned_incentive,
    :pending_incentive,
    :paid_incentive
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
