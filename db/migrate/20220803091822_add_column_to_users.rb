class AddColumnToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :is_calling_executive, :boolean
  end
end
