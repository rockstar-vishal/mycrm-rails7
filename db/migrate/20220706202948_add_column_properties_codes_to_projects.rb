class AddColumnPropertiesCodesToProjects < ActiveRecord::Migration[7.1]
  def change
    add_column :projects, :property_codes, :text, array: true, default: []
    add_index :projects, :property_codes, using: :gin
  end
end
