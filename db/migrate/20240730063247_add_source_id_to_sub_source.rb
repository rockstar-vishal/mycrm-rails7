class AddSourceIdToSubSource < ActiveRecord::Migration
  def change
    add_column :sub_sources, :source_id, :integer, index: true
  end
end
