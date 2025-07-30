class AddClientNameToCostSheets < ActiveRecord::Migration
  def change
    add_column :cost_sheets, :client_name, :string
  end
end
