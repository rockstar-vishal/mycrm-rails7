class AddIsDeactivatedToLeads < ActiveRecord::Migration[7.1]
  def change
    add_column :leads, :is_deactivated, :boolean, :default=>false
  end
end
