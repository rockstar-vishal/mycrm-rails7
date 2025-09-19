class AddOrderToStatues < ActiveRecord::Migration[7.1]
  def change
    add_column :company_statuses, :order, :integer
  end
end
