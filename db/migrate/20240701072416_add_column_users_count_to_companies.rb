class AddColumnUsersCountToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :users_count, :integer, index: true
  end
end
