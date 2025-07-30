class CreateCostSheetsPaymentPlans < ActiveRecord::Migration
  def change
    create_table :cost_sheets_payment_plans do |t|
      t.string :title
      t.decimal :percentage
      t.date :due_date
      t.integer :cost_sheet_id, index: true

      t.timestamps
    end
  end
end
