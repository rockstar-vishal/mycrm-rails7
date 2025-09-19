class AddAssignAllUsersPermissionToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :assign_all_users_permission, :boolean, default: false
  end
end
