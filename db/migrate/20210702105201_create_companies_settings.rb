class CreateCompaniesSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :companies_settings do |t|
      t.integer :company_id
      t.json  :setting_data, default: {}

      t.timestamps
    end
  end
end
