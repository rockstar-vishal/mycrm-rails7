class AddPercentageToCostSheetOtherItems < ActiveRecord::Migration[7.1]
  def change
    add_column :cost_sheets, :total_cost, :integer
    add_column :cost_sheets_other_items, :percentage, :decimal
    add_column :cost_sheets_other_items, :cost_type_id, :integer
    add_column :cost_sheets_other_items, :due_date, :date
  end
end
