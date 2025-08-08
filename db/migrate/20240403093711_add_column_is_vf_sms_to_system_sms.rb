class AddColumnIsVfSmsToSystemSms < ActiveRecord::Migration[7.1]
  def change
    add_column :system_sms, :is_vf_sms, :boolean, default: false
  end
end
