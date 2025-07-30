class ChangeDateInLeadVisit < ActiveRecord::Migration
  def up
    change_column :leads_visits, :date, :datetime
  end

  def down
    change_column :leads_visits, :datetime, :date
  end
end
