class AddColumnCommentsToInventories < ActiveRecord::Migration
  def change
    add_column :inventories, :comments, :text
  end
end
