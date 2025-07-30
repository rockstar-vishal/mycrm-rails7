class AddStatusToLeadsVisits < ActiveRecord::Migration
  def change
    add_column :leads_visits, :status_id, :integer, index: true
  end
end
