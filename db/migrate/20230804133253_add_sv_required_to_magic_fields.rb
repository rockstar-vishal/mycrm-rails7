class AddSvRequiredToMagicFields < ActiveRecord::Migration
  def change
    add_column :magic_fields, :is_sv_required, :boolean, default: nil
  end
end
