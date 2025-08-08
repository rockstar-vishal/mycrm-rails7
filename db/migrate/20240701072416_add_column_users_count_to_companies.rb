class AddColumnUsersCountToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :users_count, :integer
    add_index :companies, :users_count
  end
end
