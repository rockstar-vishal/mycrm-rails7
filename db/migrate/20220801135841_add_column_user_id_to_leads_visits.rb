class AddColumnUserIdToLeadsVisits < ActiveRecord::Migration[7.1]
  def change
    add_column :leads_visits, :user_id, :integer
    add_index :leads_visits, :user_id
  end
end
