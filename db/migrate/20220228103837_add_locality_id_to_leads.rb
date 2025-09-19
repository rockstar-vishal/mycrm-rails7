class AddLocalityIdToLeads < ActiveRecord::Migration[7.1]
  def change
    add_column :leads, :locality_id, :integer
  end
end
