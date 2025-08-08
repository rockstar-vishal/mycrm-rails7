class CreateStructureFields < ActiveRecord::Migration[7.1]
  def change
    create_table :structure_fields do |t|
      t.integer "structure_id", index: true
      t.string  "name"
      t.string  "section_heading"
      t.string  "datatype"
      t.string  "label"
      t.boolean "is_required"
      t.boolean "is_select_list"
      t.text    "items", default: [], array: true

      t.timestamps
    end
  end
end
