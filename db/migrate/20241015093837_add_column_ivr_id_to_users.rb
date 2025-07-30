class AddColumnIvrIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :ivr_id, :string
  end
end
