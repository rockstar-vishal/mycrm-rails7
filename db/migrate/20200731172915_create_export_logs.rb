class CreateExportLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :export_logs do |t|
      t.integer :company_id
      t.integer :user_id
      t.integer :count

      t.timestamps
    end
  end
end
