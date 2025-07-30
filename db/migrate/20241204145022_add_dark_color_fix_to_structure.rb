class AddDarkColorFixToStructure < ActiveRecord::Migration
  def change
    add_column :structures, :dark_color_fix, :string
  end
end
