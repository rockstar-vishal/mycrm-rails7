class CreateWebHookRequests < ActiveRecord::Migration
  def change
    create_table :web_hook_requests do |t|
      t.integer :company_id, index: true
      t.string :request_uuid
      t.string :secondary_request_uuid
      t.json :other_data

      t.timestamps
    end
  end
end
