class CreatePaymentPlans < ActiveRecord::Migration
  def change
    create_table :payment_plans do |t|
      t.string :title
      t.integer :company_id

      t.timestamps
    end
  end
end
