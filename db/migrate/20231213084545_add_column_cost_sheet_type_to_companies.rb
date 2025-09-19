class AddColumnCostSheetTypeToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :cost_sheet_letter_types, :text, array: true, default: []
  end
end
