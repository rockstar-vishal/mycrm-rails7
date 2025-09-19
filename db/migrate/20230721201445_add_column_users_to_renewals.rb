class AddColumnUsersToRenewals < ActiveRecord::Migration[7.1]
  def change
    add_column :renewals, :sales_executive_id, :integer
    add_index :renewals, :sales_executive_id
    add_column :renewals, :customer_success_executive_id, :integer
    add_index :renewals, :customer_success_executive_id
  end
end
