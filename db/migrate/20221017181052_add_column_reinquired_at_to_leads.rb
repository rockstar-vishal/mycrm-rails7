class AddColumnReinquiredAtToLeads < ActiveRecord::Migration
  def change
    add_column :leads, :reinquired_at, :datetime
  end
end
