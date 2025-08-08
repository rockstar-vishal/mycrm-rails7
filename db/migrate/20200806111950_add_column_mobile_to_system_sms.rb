class AddColumnMobileToSystemSms < ActiveRecord::Migration[7.1]
  def change
    add_column :system_sms, :mobile, :string
  end
end
