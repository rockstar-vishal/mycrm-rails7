class AddCpCodeToBrokers < ActiveRecord::Migration
  def change
    add_column :brokers, :cp_code, :string
  end
end
