class AddReraStatusToBroker < ActiveRecord::Migration[7.1]
  def change
    add_column :brokers, :rera_status, :string
  end
end
