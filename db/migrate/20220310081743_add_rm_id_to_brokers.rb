class AddRmIdToBrokers < ActiveRecord::Migration[7.1]
  def change
    add_column :brokers, :rm_id, :integer
  end
end
