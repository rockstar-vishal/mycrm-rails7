class AddUserToCostSheet < ActiveRecord::Migration
  def change
    add_column :cost_sheets, :user_id, :integer, index: true
    add_column :cost_sheets, :carpet_area, :string
  end
end
