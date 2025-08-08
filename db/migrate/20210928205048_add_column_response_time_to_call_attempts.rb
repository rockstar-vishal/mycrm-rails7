class AddColumnResponseTimeToCallAttempts < ActiveRecord::Migration[7.1]
  def change
    add_column :call_attempts, :response_time, :float
  end
end
