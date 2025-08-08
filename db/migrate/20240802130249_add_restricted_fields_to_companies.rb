class AddRestrictedFieldsToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :restricted_lead_fields, :text, array: true, default: []
  end
end
