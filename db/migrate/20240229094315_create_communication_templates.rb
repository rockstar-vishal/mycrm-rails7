class CreateCommunicationTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :communication_templates do |t|
      t.string :template_name
      t.string :notification_type
      t.integer :company_id, index: true
      t.boolean :active, default: false

      t.timestamps
    end
  end
end
