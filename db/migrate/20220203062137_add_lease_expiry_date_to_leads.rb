class AddLeaseExpiryDateToLeads < ActiveRecord::Migration[7.1]
  def change
    add_column :leads, :lease_expiry_date, :date
  end
end
