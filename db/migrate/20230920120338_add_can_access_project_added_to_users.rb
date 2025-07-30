class AddCanAccessProjectAddedToUsers < ActiveRecord::Migration
  def change
    add_column :users, :can_access_project, :boolean, default: false
  end
end
