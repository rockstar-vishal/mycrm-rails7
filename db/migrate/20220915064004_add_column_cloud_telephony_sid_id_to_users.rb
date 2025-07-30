class AddColumnCloudTelephonySidIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :cloud_telephony_sid_id, :integer, index: true
  end
end
