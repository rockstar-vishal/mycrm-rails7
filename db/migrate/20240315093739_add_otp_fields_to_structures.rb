class AddOtpFieldsToStructures < ActiveRecord::Migration[7.1]
  def change
    add_column :structures, :enable_otp, :boolean, default: false
    add_column :structures, :otp_url, :text
    add_column :structures, :otp_type, :string
    add_column :structures, :request_method, :string
  end
end
