class AddColumnProjectIdAndSourceIdToCloudTelePhonySids < ActiveRecord::Migration[7.1]
  def change
    add_column :cloud_telephony_sids, :project_id, :integer
    add_index :cloud_telephony_sids, :project_id
    add_column :cloud_telephony_sids, :source_id, :integer
    add_index :cloud_telephony_sids, :source_id
  end
end
