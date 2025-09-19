class AddPositionToStructureFields < ActiveRecord::Migration[7.1]
  def change
    add_column :structure_fields, :field_position, :integer
    add_column :magic_fields, :field_position, :integer
  end
end
