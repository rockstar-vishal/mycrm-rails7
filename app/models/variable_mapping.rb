class VariableMapping < ActiveRecord::Base

  validates :name, :variable_type, :system_assoication, :system_attribute, presence: true
end