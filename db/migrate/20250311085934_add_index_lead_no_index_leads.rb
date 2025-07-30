class AddIndexLeadNoIndexLeads < ActiveRecord::Migration
  def change
  	add_index :leads, :lead_no
  	add_index :leads_call_logs, :sid
  end
end
