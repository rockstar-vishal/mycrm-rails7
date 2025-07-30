class AddPartnerLeadNoToLeads < ActiveRecord::Migration
  def change
    add_column :leads, :partner_lead_no, :string
  end
end
