class AddBrokerIdToLeads < ActiveRecord::Migration[7.1]
  def change
    add_column :leads, :broker_id, :integer
  end
end
