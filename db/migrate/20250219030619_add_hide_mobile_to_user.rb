class AddHideMobileToUser < ActiveRecord::Migration
  def change
    add_column :users, :hide_number, :boolean, default: false, null: false
  end
end
