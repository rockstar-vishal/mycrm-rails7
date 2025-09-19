class AddIsSiteVisitDoneToLeads < ActiveRecord::Migration[7.1]
  def change
    add_column :leads, :is_site_visit_scheduled, :boolean, default: false
  end
end
