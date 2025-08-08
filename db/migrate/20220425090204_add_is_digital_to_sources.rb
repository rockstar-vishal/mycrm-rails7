class AddIsDigitalToSources < ActiveRecord::Migration[7.1]
  def change
    add_column :sources, :is_digital, :boolean, default: false
  end
end
