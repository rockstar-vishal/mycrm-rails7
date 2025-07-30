class AddIndexInLeadsVisits < ActiveRecord::Migration
  def change
    add_index :leads_visits, :is_visit_executed
    add_index :leads_visits, :date
    add_index :leads_visits, :lead_id
  end
end
