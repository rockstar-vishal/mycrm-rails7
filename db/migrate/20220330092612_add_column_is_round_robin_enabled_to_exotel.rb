class AddColumnIsRoundRobinEnabledToExotel < ActiveRecord::Migration[7.1]
  def change
    add_column :exotel_sids, :is_round_robin_enabled, :boolean, default: false
  end
end
