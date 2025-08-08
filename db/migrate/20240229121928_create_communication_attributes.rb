class CreateCommunicationAttributes < ActiveRecord::Migration[7.1]
  def change
    create_table :communication_attributes do |t|
      t.string :text
      t.integer :variable_mapping_id, index: true
      t.integer :trigger_event_id, index: true

      t.timestamps
    end
  end
end
