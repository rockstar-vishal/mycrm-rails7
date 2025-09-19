class AddColumnCommentsToInventories < ActiveRecord::Migration[7.1]
  def change
    add_column :inventories, :comments, :text
  end
end
