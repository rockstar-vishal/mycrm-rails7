class AddColumnToMcubeSids < ActiveRecord::Migration[7.1]
  def change
    add_column :mcube_sids, :default_numbers, :text, default: [], array: true
    add_column :mcube_sids, :is_round_robin_enabled, :boolean, default: false
  end
end
