class AddCpCodeToBrokers < ActiveRecord::Migration[7.1]
  def change
    add_column :brokers, :cp_code, :string
  end
end
