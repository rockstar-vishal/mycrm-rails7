class CreateCostSheetsOtherItems < ActiveRecord::Migration[7.1]
  def change
    create_table :cost_sheets_other_items do |t|
      t.string :name
      t.integer :amount
      t.integer :slab_operator
      t.integer :cost_sheet_id, index: true

      t.timestamps
    end
  end
end
