class AddAddressToBrokers < ActiveRecord::Migration
  def change
    add_column :brokers, :address, :string
  end
end
