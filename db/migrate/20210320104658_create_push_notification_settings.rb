class CreatePushNotificationSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :push_notification_settings do |t|
      t.string :token
      t.string :project_key
      t.integer :company_id
      t.boolean :is_active, default: false

      t.timestamps
    end
    add_index :push_notification_settings, :company_id
  end
end
