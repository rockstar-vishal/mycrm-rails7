class AddFieldsToExportLogs < ActiveRecord::Migration
  def change
    add_column :export_logs, :target_ids, :text, array: true
    add_column :export_logs, :target_type, :string
  end
end
