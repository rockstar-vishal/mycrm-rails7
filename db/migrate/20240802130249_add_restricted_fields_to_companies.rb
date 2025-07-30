class AddRestrictedFieldsToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :restricted_lead_fields, :text, array: true, default: []
  end
end
