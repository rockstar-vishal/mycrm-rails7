class AddIndexesToLeadsCallLogs < ActiveRecord::Migration
  def up
    # We use execute with raw SQL for expression indexes on older Rails versions.
    execute <<-SQL
      CREATE INDEX idx_leads_cl_on_od_direction
      ON leads_call_logs ((other_data->>'direction'));
    SQL

    execute <<-SQL
      CREATE INDEX idx_leads_cl_on_od_status
      ON leads_call_logs ((other_data->>'status'));
    SQL

    # The standard index on lead_id can be added normally.
    add_index :leads_call_logs, :lead_id
    add_index :leads_call_logs, :user_id
  end

  def down
    # We must explicitly define how to reverse (or "drop") the indexes.
    remove_index :leads_call_logs, name: 'idx_leads_cl_on_od_direction'
    remove_index :leads_call_logs, name: 'idx_leads_cl_on_od_status'
    remove_index :leads_call_logs, :lead_id
    remove_index :leads_call_logs, :user_id
  end
end
