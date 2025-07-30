class AddSCustomizeDashboardStatusIdsToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :customize_report_status_ids, :text, array: true, default: []
  end
end
