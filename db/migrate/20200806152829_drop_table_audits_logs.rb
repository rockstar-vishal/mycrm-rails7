class DropTableAuditsLogs < ActiveRecord::Migration[7.1]
  def change
    drop_table :audit_logs
  end
end
