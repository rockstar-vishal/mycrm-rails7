class AddSourceIdToSubSource < ActiveRecord::Migration[7.1]
  def change
    add_column :sub_sources, :source_id, :integer
    add_index :sub_sources, :source_id
  end
end
