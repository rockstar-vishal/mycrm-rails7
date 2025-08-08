class AddColumnCampaignIdToCompaniesFbForms < ActiveRecord::Migration[7.1]
  def change
    add_column :companies_fb_forms, :campaign_id, :integer
    add_index :companies_fb_forms, :campaign_id
  end
end
