class AddColumnWingToInventories < ActiveRecord::Migration[7.1]
  def change
    add_column :inventories, :wing, :string
  end
end
