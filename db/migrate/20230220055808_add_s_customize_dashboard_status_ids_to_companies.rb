class AddSCustomizeDashboardStatusIdsToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :customize_report_status_ids, :text, array: true, default: []
  end
end
