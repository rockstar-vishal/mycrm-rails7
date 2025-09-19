class AddRequiredFieldsToCompany < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :required_fields, :text, array: true, default: []
  end
end
