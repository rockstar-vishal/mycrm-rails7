class CreatePaymentPlans < ActiveRecord::Migration[7.1]
  def change
    create_table :payment_plans do |t|
      t.string :title
      t.integer :company_id

      t.timestamps
    end
  end
end
