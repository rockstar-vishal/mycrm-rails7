class AddUserToCostSheet < ActiveRecord::Migration[7.1]
  def change
    add_column :cost_sheets, :user_id, :integer
    add_index :cost_sheets, :user_id
    add_column :cost_sheets, :carpet_area, :string
  end
end
