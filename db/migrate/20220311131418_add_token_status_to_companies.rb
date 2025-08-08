class AddTokenStatusToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :token_status_ids, :text, array: true, default: []
  end
end
