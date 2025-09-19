class AddColumnSubSourceIdToMcubeIds < ActiveRecord::Migration[7.1]
  def change
    add_column :mcube_sids, :sub_source_id, :integer
    add_index :mcube_sids, :sub_source_id
  end
end
