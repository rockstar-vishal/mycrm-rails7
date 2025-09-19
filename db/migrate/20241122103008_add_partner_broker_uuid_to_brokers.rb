class AddPartnerBrokerUuidToBrokers < ActiveRecord::Migration[7.1]
  def change
    add_column :brokers, :partner_broker_uuid, :string
  end
end
