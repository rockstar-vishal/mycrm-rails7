class AddColumnCompanyIdToInventories < ActiveRecord::Migration[7.1]
  def change
    add_column :inventories, :company_id, :integer
    add_index :inventories, :company_id
  end
end
