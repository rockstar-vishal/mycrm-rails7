class AddIndexingToMagicAttributes < ActiveRecord::Migration[7.1]
  def change
    add_index "magic_attributes", [:magic_field_id, :value]
  end
end
