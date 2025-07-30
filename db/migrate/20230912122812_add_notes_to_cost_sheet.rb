class AddNotesToCostSheet < ActiveRecord::Migration
  def change
    add_column :cost_sheets, :notes, :text
  end
end
