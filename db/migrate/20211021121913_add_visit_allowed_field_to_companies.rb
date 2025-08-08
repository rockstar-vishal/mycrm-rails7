class AddVisitAllowedFieldToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :visits_allowed_fields, :text, array: true, default: []
  end
end
