class AddHotStatusIdToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :hot_status_id, :integer
  end
end
