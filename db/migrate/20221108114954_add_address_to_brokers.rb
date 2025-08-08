class AddAddressToBrokers < ActiveRecord::Migration[7.1]
  def change
    add_column :brokers, :address, :string
  end
end
