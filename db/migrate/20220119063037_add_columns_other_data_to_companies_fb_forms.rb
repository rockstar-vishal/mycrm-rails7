class AddColumnsOtherDataToCompaniesFbForms < ActiveRecord::Migration[7.1]
  def change
    add_column :companies_fb_forms, :other_data, :json, default: {}
  end
end
