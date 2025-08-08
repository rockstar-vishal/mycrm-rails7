class CreateLocalities < ActiveRecord::Migration[7.1]
  def change
    create_table :localities do |t|
      t.string :name
      t.integer :region_id

      t.timestamps
    end
  end
end
