class AddMigrationProjectIdToExotelSids < ActiveRecord::Migration[7.1]
  def change
    add_column :exotel_sids, :project_id, :integer
  end
end
