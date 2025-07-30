class AddColumnProjectIdAndSourceIdToCloudTelePhonySids < ActiveRecord::Migration
  def change
    add_column :cloud_telephony_sids, :project_id, :integer, index: true
    add_column :cloud_telephony_sids, :source_id, :integer, index: true
  end
end
