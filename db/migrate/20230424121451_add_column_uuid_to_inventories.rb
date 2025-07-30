class AddColumnUuidToInventories < ActiveRecord::Migration

  def change
    add_column :inventories, :uuid, :uuid, default: "uuid_generate_v4()"
  end

end
