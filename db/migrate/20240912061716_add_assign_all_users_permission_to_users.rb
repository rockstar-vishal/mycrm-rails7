class AddAssignAllUsersPermissionToUsers < ActiveRecord::Migration
  def change
    add_column :users, :assign_all_users_permission, :boolean, default: false
  end
end
