class AddTokenDateToLeads < ActiveRecord::Migration[7.1]
  def change
    add_column :leads, :token_date, :date
  end
end
