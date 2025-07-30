class AddSectionNameToOtherItems < ActiveRecord::Migration
  def change
    add_column :cost_sheets_other_items, :section_name, :string
  end
end
