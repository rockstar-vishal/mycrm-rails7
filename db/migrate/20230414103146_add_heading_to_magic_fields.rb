class AddHeadingToMagicFields < ActiveRecord::Migration
  def change
    add_column :magic_fields, :section_heading, :string
  end
end
