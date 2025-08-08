class AddColumnLeadIdToNotifications < ActiveRecord::Migration[7.1]
  def change
    add_column :notifications, :lead_id, :integer
  end
end
