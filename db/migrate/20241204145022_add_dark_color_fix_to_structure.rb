class AddDarkColorFixToStructure < ActiveRecord::Migration[7.1]
  def change
    add_column :structures, :dark_color_fix, :string
  end
end
