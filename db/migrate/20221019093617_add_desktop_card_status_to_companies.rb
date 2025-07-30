class AddDesktopCardStatusToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :card_status, :text, array: true, default: []
  end
end
