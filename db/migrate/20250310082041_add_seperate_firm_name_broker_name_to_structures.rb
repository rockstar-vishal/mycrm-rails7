class AddSeperateFirmNameBrokerNameToStructures < ActiveRecord::Migration[7.1]
  def change
    add_column :structures, :seperate_firm_name_broker_name, :boolean, default: false
  end
end
