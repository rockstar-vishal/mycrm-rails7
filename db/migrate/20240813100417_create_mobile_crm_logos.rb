class CreateMobileCrmLogos < ActiveRecord::Migration
  def change
    create_table :mobile_crm_logos do |t|
      t.integer "company_id"

      t.timestamps
    end
    add_attachment :mobile_crm_logos, :small_icon
    add_attachment :mobile_crm_logos, :large_icon
    add_attachment :mobile_crm_logos, :small_maskable_icon
    add_attachment :mobile_crm_logos, :large_maskable_icon
    add_attachment :mobile_crm_logos, :apple_icon
    add_attachment :mobile_crm_logos, :masked_icon
    add_attachment :mobile_crm_logos, :tile_image
  end
end
