class AddOtherConstactsToBrokers < ActiveRecord::Migration[7.1]
  def change
    add_column :brokers, :other_contacts, :string
  end
end
