class AddColumnLeadIdToMagicAttributes < ActiveRecord::Migration
  def change
    add_column :magic_attributes, :lead_id, :integer, index: true
  end
end
