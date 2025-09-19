class AddDisabledFieldsToStructures < ActiveRecord::Migration[7.1]
  def change
    add_column :structures, :disabled_sv_fields, :text, array: true, default: []
  end
end
