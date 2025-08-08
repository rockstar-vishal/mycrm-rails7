class AddColumnDefaultNumbersToExotelsSids < ActiveRecord::Migration[7.1]
  def change
    add_column :exotel_sids, :default_numbers, :text, default: [], array: true
  end
end
