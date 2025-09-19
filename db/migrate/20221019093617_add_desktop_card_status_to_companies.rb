class AddDesktopCardStatusToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :card_status, :text, array: true, default: []
  end
end
