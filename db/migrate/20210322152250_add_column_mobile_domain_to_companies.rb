class AddColumnMobileDomainToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :mobile_domain, :string
  end
end
