class AddColumnTemplateIdToNotificationTemplates < ActiveRecord::Migration[7.1]
  def change
    add_column :notification_templates, :template_id, :string
  end
end
