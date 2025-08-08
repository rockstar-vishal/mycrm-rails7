class AddRemoveClosedToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :remove_closed, :boolean, default: false
  end
end
