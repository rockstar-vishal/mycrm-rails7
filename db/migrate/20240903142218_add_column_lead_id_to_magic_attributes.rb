class AddColumnLeadIdToMagicAttributes < ActiveRecord::Migration[7.1]
  def change
    add_column :magic_attributes, :lead_id, :integer
    add_index :magic_attributes, :lead_id
  end
end
