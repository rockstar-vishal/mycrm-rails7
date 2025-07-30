class AddColumnsClosingExecutiveTriggerStatuses < ActiveRecord::Migration
  def change
    add_column :companies, :closing_executive_trigger_statuses, :text, default: [], array: true
  end
end
