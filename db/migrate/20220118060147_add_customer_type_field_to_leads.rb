class AddCustomerTypeFieldToLeads < ActiveRecord::Migration[7.1]
  def change
    add_column :leads, :customer_type, :integer
  end
end
