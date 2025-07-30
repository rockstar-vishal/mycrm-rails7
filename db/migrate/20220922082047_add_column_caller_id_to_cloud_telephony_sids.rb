class AddColumnCallerIdToCloudTelephonySids < ActiveRecord::Migration
  def change
    add_column :cloud_telephony_sids, :caller_id, :string
  end
end
