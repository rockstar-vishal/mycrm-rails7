class AddReraStatusToBroker < ActiveRecord::Migration
  def change
    add_column :brokers, :rera_status, :string
  end
end
