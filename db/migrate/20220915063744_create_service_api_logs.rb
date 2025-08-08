class CreateServiceApiLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :service_api_logs do |t|
      t.integer :entry_type, index: true
      t.json :payload, null: false, default: {}
      
      t.timestamps
    end
  end
end
