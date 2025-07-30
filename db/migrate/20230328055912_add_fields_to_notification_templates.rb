class AddFieldsToNotificationTemplates < ActiveRecord::Migration
  def change
    add_column :notification_templates, :sender_id, :string
    add_column :notification_templates, :notification_category, :string
  end
end
