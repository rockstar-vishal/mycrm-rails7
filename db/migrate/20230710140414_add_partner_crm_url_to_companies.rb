class AddPartnerCrmUrlToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :partner_crm_url, :string
  end
end
