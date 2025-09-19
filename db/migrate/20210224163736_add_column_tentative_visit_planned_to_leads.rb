class AddColumnTentativeVisitPlannedToLeads < ActiveRecord::Migration[7.1]
  def change
    add_column :leads, :tentative_visit_planned, :datetime
  end
end
