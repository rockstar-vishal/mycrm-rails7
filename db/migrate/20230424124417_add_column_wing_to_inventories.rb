class AddColumnWingToInventories < ActiveRecord::Migration
  def change
    add_column :inventories, :wing, :string
  end
end
