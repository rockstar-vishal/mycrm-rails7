class AddDataFieldToStructures < ActiveRecord::Migration[7.1]
  def change
    add_column :structures, :other_data, :json, default: {}
  end
end
