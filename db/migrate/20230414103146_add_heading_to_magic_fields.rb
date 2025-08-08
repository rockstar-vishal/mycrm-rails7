class AddHeadingToMagicFields < ActiveRecord::Migration[7.1]
  def change
    add_column :magic_fields, :section_heading, :string
  end
end
