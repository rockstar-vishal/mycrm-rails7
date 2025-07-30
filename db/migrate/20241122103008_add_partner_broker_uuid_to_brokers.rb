class AddPartnerBrokerUuidToBrokers < ActiveRecord::Migration
  def change
    add_column :brokers, :partner_broker_uuid, :string
  end
end
