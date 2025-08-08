class AddRoundRobinEnabledToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :round_robin_enabled, :boolean, default: false
    add_column :users, :round_robin_enabled, :boolean, default: false
  end
end
