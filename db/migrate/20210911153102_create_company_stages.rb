class CreateCompanyStages < ActiveRecord::Migration[7.1]
  def change
    create_table :company_stages do |t|
      t.integer :stage_id, index: true
      t.integer :company_id, index: true
      t.timestamps
    end
  end
end
