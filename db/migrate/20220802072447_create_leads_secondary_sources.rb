class CreateLeadsSecondarySources < ActiveRecord::Migration[7.1]
  def change
    create_table :leads_secondary_sources do |t|
      t.integer :lead_id
      t.integer :source_id
      
      t.timestamps
    end
  end
end
