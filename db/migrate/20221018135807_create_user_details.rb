class CreateUserDetails < ActiveRecord::Migration[7.1]
  def change
    create_table :user_details do |t|
      t.integer :user_id
      t.json  :other_data, default: {}
      t.timestamps
    end
  end
end
