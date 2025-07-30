class AddColumnCompanyIdToInventories < ActiveRecord::Migration
  def change
    add_column :inventories, :company_id, :integer, index: true
  end
end
