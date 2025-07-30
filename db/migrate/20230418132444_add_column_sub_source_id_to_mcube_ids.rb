class AddColumnSubSourceIdToMcubeIds < ActiveRecord::Migration
  def change
    add_column :mcube_sids, :sub_source_id, :integer, index: true
  end
end
