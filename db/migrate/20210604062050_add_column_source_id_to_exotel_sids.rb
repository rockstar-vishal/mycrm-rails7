class AddColumnSourceIdToExotelSids < ActiveRecord::Migration[7.1]
  def change
    add_column :exotel_sids, :source_id, :integer
    add_index :exotel_sids, :source_id
  end
end
