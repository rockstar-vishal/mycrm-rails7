class AddSvRequiredToMagicFields < ActiveRecord::Migration[7.1]
  def change
    add_column :magic_fields, :is_sv_required, :boolean, default: nil
  end
end
