class CreateCompanyStatuses < ActiveRecord::Migration[7.1]
  def change
    create_table :company_statuses do |t|
      t.integer :company_id, index: true
      t.integer :status_id, index: true

      t.timestamps
    end
  end
end
