class AddUuidToStages < ActiveRecord::Migration[7.1]
  def change
    add_column :stages, :uuid, :uuid, default: "uuid_generate_v4()"
  end
end
