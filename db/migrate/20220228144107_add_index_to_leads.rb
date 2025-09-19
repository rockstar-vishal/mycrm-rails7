class AddIndexToLeads < ActiveRecord::Migration[7.1]
  def change
    add_index :leads, :locality_id
  end
end
