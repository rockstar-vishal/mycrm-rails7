class CreateCostSheets < ActiveRecord::Migration
  def change
    create_table :cost_sheets do |t|
      t.string :project_name
      t.string :building_name
      t.string :topology
      t.string :flat_no
      t.string :agreement_value
      t.string :gst
      t.integer :company_id, index: true
      t.integer :payment_plan_id, index: true

      t.timestamps
    end
  end
end
