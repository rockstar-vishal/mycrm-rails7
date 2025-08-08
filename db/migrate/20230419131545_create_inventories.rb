class CreateInventories < ActiveRecord::Migration[7.1]
  def change
    create_table :inventories do |t|
      t.string :developer
      t.string :development
      t.string :location
      t.string :floor
      t.string :unit
      t.string :carpet
      t.integer :configuration_id
      t.string :parking
      t.string :quote
      t.string :poc
      t.string :property
      t.string :contact

      t.timestamps
    end
  end
end
