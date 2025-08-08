class AddColumnCallerIdToCloudTelephonySids < ActiveRecord::Migration[7.1]
  def change
    add_column :cloud_telephony_sids, :caller_id, :string
  end
end
