class AddDefaultFromToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :default_from_email, :string
  end
end
