class CreateCustomLabels < ActiveRecord::Migration[7.1]
  def change
    create_table :custom_labels do |t|
      t.string :default_value
      t.string :custom_value
      t.string :key
      t.integer :company_id

      t.timestamps
    end
  end
end
