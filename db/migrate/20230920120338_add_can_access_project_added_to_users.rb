class AddCanAccessProjectAddedToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :can_access_project, :boolean, default: false
  end
end
