class AddColumnIvrIdToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :ivr_id, :string
  end
end
