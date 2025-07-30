class AddIndexToStatusIdInLeads < ActiveRecord::Migration
  def change
    add_index :leads, :status_id
  end
end
