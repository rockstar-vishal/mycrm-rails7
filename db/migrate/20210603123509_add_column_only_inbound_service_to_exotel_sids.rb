class AddColumnOnlyInboundServiceToExotelSids < ActiveRecord::Migration[7.1]
  def change
    add_column :exotel_sids, :only_inbound_service, :boolean, default: :false
  end
end
