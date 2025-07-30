class AddSourceIdToLeadsVisits < ActiveRecord::Migration
  def change
    add_column :leads_visits, :source_id, :integer, index: true
  end
end
