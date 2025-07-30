class AddFieldsInCampaignsAndLeads < ActiveRecord::Migration
  def change
    add_column :campaigns, :targeted_leads, :integer
    add_column :campaigns, :targeted_ql, :integer
    add_column :campaigns, :targeted_sv, :integer
    add_column :campaigns, :targeted_bookings, :integer

    add_column :leads, :is_qualified, :boolean, default: false
  end
end
