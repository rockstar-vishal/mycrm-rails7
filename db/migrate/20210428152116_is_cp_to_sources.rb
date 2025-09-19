class IsCpToSources < ActiveRecord::Migration[7.1]
  def change
    add_column :sources, :is_cp, :boolean, default: false
  end
end
