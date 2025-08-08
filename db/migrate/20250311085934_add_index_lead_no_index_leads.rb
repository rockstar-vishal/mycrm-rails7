class AddIndexLeadNoIndexLeads < ActiveRecord::Migration[7.1]
  def change
  	add_index :leads, :lead_no
  	add_index :leads_call_logs, :sid
  end
end
