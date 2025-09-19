class AddBreakNameFieldToStructures < ActiveRecord::Migration[7.1]
  def change
    add_column :structures, :break_name_field, :boolean, default: false
  end
end
