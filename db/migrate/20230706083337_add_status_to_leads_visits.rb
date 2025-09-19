class AddStatusToLeadsVisits < ActiveRecord::Migration[7.1]
  def change
    add_column :leads_visits, :status_id, :integer
    add_index :leads_visits, :status_id
  end
end
