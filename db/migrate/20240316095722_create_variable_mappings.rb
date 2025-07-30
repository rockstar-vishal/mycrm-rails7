class CreateVariableMappings < ActiveRecord::Migration
  def change
    create_table :variable_mappings do |t|
      t.string :name
      t.string :variable_type
      t.string :system_assoication
      t.string :system_attribute

      t.timestamps
    end
  end
end
