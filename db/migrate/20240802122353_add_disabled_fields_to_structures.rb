class AddDisabledFieldsToStructures < ActiveRecord::Migration
  def change
    add_column :structures, :disabled_sv_fields, :text, array: true, default: []
  end
end
