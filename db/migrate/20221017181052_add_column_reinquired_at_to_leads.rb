class AddColumnReinquiredAtToLeads < ActiveRecord::Migration[7.1]
  def change
    add_column :leads, :reinquired_at, :datetime
  end
end
