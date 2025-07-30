class CreatePlanStages < ActiveRecord::Migration
  def change
    create_table :plan_stages do |t|
      t.string :title
      t.decimal :percentage
      t.integer :payment_plan_id

      t.timestamps
    end
  end
end
