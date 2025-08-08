class CreateStructures < ActiveRecord::Migration[7.1]
  def change
    create_table :structures do |t|
      t.integer :company_id, index: true
      t.string :key
      t.string :title
      t.string :domain

      t.timestamps
    end
  end
end
