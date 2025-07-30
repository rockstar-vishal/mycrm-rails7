class AddPartnerIdToLeads < ActiveRecord::Migration
  def change
    add_column :leads, :partner_id, :integer, index: true
  end
end
