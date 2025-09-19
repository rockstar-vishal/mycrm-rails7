class AddColumnOtherDataToLeads < ActiveRecord::Migration[7.1]
  def change
    add_column :leads, :other_data, :json, default: {}
  end
end
