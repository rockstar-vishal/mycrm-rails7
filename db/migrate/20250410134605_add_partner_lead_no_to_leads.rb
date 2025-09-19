class AddPartnerLeadNoToLeads < ActiveRecord::Migration[7.1]
  def change
    add_column :leads, :partner_lead_no, :string
  end
end
