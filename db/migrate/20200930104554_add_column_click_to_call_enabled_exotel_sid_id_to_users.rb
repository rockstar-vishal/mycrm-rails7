class AddColumnClickToCallEnabledExotelSidIdToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :click_to_call_enabled, :boolean
    add_column :users, :exotel_sid_id, :integer
  end
end
