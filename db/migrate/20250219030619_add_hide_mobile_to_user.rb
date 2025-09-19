class AddHideMobileToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :hide_number, :boolean, default: false, null: false
  end
end
