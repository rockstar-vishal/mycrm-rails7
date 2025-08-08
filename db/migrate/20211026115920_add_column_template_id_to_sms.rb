class AddColumnTemplateIdToSms < ActiveRecord::Migration[7.1]
  def change
    add_column :system_sms, :template_id, :string
  end
end
