class AddNotesToCostSheet < ActiveRecord::Migration[7.1]
  def change
    add_column :cost_sheets, :notes, :text
  end
end
