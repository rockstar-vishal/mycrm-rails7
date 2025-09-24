class CreateWhatsappMessageLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :whatsapp_message_logs do |t|
      t.integer :lead_id
      t.string :campaign_name
      t.string :destination
      t.text :template_params
      t.integer :status, default: 0
      t.text :response
      t.timestamps
    end
  end
end
