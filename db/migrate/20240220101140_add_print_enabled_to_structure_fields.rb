class AddPrintEnabledToStructureFields < ActiveRecord::Migration
  def change
    add_column :structure_fields, :print_enabled, :boolean, default: true
    add_column :magic_fields, :print_enabled, :boolean, default: true
  end
end
