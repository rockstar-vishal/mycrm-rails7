class AddSeperateFirmNameBrokerNameToStructures < ActiveRecord::Migration
  def change
    add_column :structures, :seperate_firm_name_broker_name, :boolean, default: false
  end
end
