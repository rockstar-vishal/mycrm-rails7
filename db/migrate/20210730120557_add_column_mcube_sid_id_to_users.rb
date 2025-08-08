class AddColumnMcubeSidIdToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :mcube_sid_id, :integer
    add_index :users, :mcube_sid_id
  end
end
