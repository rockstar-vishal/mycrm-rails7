class AddClientNameToCostSheets < ActiveRecord::Migration[7.1]
  def change
    add_column :cost_sheets, :client_name, :string
  end
end
