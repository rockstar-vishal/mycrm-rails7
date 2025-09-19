class CreateIncomingCalls < ActiveRecord::Migration[7.1]
  def change
    create_table :incoming_calls do |t|
      t.string :from_number
      t.string :start_time
      t.string :phone_number_sid

      t.timestamps
    end
  end
end
