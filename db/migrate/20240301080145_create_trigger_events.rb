class CreateTriggerEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :trigger_events do |t|
      t.integer :from_status
      t.integer :to_status
      t.datetime :ncd
      t.string :object_entity
      t.string :receiver_type
      t.string :trigger_type
      t.string :trigger_hook_type
      t.string :template_id, index: true
      t.integer :communication_template_id, index: true

      t.timestamps
    end
  end
end
