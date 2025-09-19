class AddFieldsToNotificationTemplates < ActiveRecord::Migration[7.1]
  def change
    add_column :notification_templates, :sender_id, :string
    add_column :notification_templates, :notification_category, :string
  end
end
