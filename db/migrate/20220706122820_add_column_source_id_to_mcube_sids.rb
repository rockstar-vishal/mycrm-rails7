class AddColumnSourceIdToMcubeSids < ActiveRecord::Migration[7.1]
  def change
    add_column :mcube_sids, :source_id, :integer
    add_index :mcube_sids, :source_id
  end
end
