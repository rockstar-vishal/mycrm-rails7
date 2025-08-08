class CreateExotelSids < ActiveRecord::Migration[7.1]
  def change
    create_table :exotel_sids do |t|
      t.string :number
      t.string :description
      t.boolean :is_active, default: true
      t.integer :company_id
      t.uuid :uuid, default: "uuid_generate_v4()"

      t.timestamps
    end
    add_index :exotel_sids, :company_id
  end
end
