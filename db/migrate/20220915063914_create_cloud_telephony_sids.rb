class CreateCloudTelephonySids < ActiveRecord::Migration
  def change
    create_table :cloud_telephony_sids do |t|
      t.string :number
      t.string :description
      t.boolean :is_active
      t.integer :company_id, index: true
      t.integer :vendor, index: true

      t.timestamps
    end
  end
end
