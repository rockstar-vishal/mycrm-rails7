class AddColumnNotificationTemplateIdToNotification < ActiveRecord::Migration[7.1]
  def change
    add_column :notifications, :notification_template_id, :integer
    add_index :notifications, :notification_template_id
  end
end
