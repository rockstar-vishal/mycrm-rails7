class AddIndexToMagicFieldIdInMagicAttributes < ActiveRecord::Migration[7.1]
  def change
    add_index :magic_attributes, :magic_field_id, name: 'index_magic_attributes_on_magic_field_id'
    add_index :magic_attributes, :value, name: 'index_magic_attributes_on_value'
  end
end
