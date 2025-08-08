class AddColumnDeviceTypeToPushNotificationLogs < ActiveRecord::Migration[7.1]
  def change
    add_column :push_notification_logs, :device_type, :integer
  end
end
