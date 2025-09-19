class ChangeColumnFieldsToNotifications < ActiveRecord::Migration[7.1]
  def change
    change_column :notifications, :field, "JSON USING CAST(field AS json)"
  end
end
