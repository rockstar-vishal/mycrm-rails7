class AddDataFieldToStructures < ActiveRecord::Migration
  def change
    add_column :structures, :other_data, :json, default: {}
  end
end
