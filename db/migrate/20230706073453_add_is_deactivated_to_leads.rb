class AddIsDeactivatedToLeads < ActiveRecord::Migration
  def change
    add_column :leads, :is_deactivated, :boolean, :default=>false
  end
end
