class AddBgColorToStructure < ActiveRecord::Migration[7.1]
  def change
    add_column :structures, :bg_color, :string
    add_column :structures, :primary_color, :string
  end
end
