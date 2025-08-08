class AddTitleToCompaniesFbForms < ActiveRecord::Migration[7.1]
  def change
    add_column :companies_fb_forms, :title, :string
  end
end
