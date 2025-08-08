class AddConversionDateToLeads < ActiveRecord::Migration[7.1]
  def change
    add_column :leads, :conversion_date, :date
  end
end
