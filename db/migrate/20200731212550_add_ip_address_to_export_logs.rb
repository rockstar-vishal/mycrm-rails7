class AddIpAddressToExportLogs < ActiveRecord::Migration[7.1]
  def change
    add_column :export_logs, :ip_address, :inet
  end
end
