class AddColumnThirdPartyIdToCallLogs < ActiveRecord::Migration[7.1]
  def change
    add_column :leads_call_logs, :third_party_id, :integer, default: 1
  end
end
