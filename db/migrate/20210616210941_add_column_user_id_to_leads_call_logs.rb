class AddColumnUserIdToLeadsCallLogs < ActiveRecord::Migration[7.1]
  def change
    add_column :leads_call_logs, :user_id, :integer
    add_index :leads_call_logs, :user_id
  end
end
