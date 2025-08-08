class AddNewStatusIdToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :new_status_id, :integer
  end
end
