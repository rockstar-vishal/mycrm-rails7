class AddCanExportToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :can_export, :boolean, default: false
  end
end
