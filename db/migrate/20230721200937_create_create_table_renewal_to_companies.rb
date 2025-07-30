class CreateCreateTableRenewalToCompanies < ActiveRecord::Migration
  def change
    create_table :renewals do |t|
      t.date :start_date
      t.date :end_date
      t.integer :company_id, index: true

      t.timestamps
    end
  end
end
