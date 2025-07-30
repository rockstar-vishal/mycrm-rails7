class AddColumnUsersToRenewals < ActiveRecord::Migration
  def change
    add_column :renewals, :sales_executive_id, :integer, index: true
    add_column :renewals, :customer_success_executive_id, :integer, index: true
  end
end
