class AddPartnerCrmUrlToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :partner_crm_url, :string
  end
end
