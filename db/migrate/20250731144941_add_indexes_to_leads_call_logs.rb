class AddIndexesToLeadsCallLogs < ActiveRecord::Migration[7.1]
  def up
    # We use execute with raw SQL for expression indexes on older Rails versions.
    execute <<-SQL
      CREATE INDEX IF NOT EXISTS idx_leads_cl_on_od_direction
      ON leads_call_logs ((other_data->>'direction'));
    SQL

    execute <<-SQL
      CREATE INDEX IF NOT EXISTS idx_leads_cl_on_od_status
      ON leads_call_logs ((other_data->>'status'));
    SQL

    # The standard index on lead_id can be added normally.
    add_index :leads_call_logs, :lead_id, if_not_exists: true
    add_index :leads_call_logs, :user_id, if_not_exists: true
  end

  def down
    # We must explicitly define how to reverse (or "drop") the indexes.
    remove_index :leads_call_logs, name: 'idx_leads_cl_on_od_direction', if_exists: true
    remove_index :leads_call_logs, name: 'idx_leads_cl_on_od_status', if_exists: true
    remove_index :leads_call_logs, :lead_id, if_exists: true
    remove_index :leads_call_logs, :user_id, if_exists: true
  end
end
