class AddPartnerIdToLeads < ActiveRecord::Migration[7.1]
  def change
    add_column :leads, :partner_id, :integer
    add_index :leads, :partner_id
  end
end
