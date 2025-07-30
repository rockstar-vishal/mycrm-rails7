class AddColumnsLastUserAssignedDateAndLastUserAssignedByToLeads < ActiveRecord::Migration
  def change
    add_column :leads, :last_user_assigned_date, :datetime
    add_column :leads, :last_modified_by, :integer
  end
end
