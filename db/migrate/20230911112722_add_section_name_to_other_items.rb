class AddSectionNameToOtherItems < ActiveRecord::Migration[7.1]
  def change
    add_column :cost_sheets_other_items, :section_name, :string
  end
end
