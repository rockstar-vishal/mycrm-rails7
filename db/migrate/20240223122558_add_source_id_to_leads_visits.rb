class AddSourceIdToLeadsVisits < ActiveRecord::Migration[7.1]
  def change
    add_column :leads_visits, :source_id, :integer
    add_index :leads_visits, :source_id
  end
end
