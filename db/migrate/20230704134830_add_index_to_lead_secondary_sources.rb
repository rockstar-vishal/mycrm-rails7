class AddIndexToLeadSecondarySources < ActiveRecord::Migration
  def change
    add_index :leads_secondary_sources, :lead_id
    add_index :leads_secondary_sources, :source_id
  end
end
