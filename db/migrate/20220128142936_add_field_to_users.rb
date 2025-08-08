class AddFieldToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :can_delete_lead, :boolean, default: false
  end
end
