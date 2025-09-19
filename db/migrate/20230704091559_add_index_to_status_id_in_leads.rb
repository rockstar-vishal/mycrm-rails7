class AddIndexToStatusIdInLeads < ActiveRecord::Migration[7.1]
  def change
    add_index :leads, :status_id
  end
end
