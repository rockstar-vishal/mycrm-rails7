class AddOrderToStatues < ActiveRecord::Migration
  def change
    add_column :company_statuses, :order, :integer
  end
end
