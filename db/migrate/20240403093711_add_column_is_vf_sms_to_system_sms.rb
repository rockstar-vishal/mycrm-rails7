class AddColumnIsVfSmsToSystemSms < ActiveRecord::Migration
  def change
    add_column :system_sms, :is_vf_sms, :boolean, default: false
  end
end
