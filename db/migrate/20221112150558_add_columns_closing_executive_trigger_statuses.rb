class AddColumnsClosingExecutiveTriggerStatuses < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :closing_executive_trigger_statuses, :text, default: [], array: true
  end
end
