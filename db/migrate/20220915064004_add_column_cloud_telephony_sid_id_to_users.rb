class AddColumnCloudTelephonySidIdToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :cloud_telephony_sid_id, :integer
    add_index :users, :cloud_telephony_sid_id
  end
end
