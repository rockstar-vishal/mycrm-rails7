class AddIndexingToMagicAttributes < ActiveRecord::Migration
  def change
    add_index "magic_attributes", [:magic_field_id, :value]
  end
end
