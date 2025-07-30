class AddBreakNameFieldToStructures < ActiveRecord::Migration
  def change
    add_column :structures, :break_name_field, :boolean, default: false
  end
end
