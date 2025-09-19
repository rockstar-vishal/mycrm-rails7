class CreateFileExports < ActiveRecord::Migration[7.1]
  def change
    create_table :file_exports do |t|
      t.binary :data
      t.string :file_name
      t.integer :user_id, index: true
      t.integer :company_id, index: true
      t.boolean :is_ready, default: false

      t.timestamps
    end
  end
end
