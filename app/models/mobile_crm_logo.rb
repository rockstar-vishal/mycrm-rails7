class MobileCrmLogo < ActiveRecord::Base
  belongs_to :company
  has_attached_file :small_icon
  validates_attachment_content_type  :small_icon,
                    content_type: ['image/jpeg', 'image/png']
  has_attached_file :large_icon
  validates_attachment_content_type  :large_icon,
                    content_type: ['image/jpeg', 'image/png']
  has_attached_file :small_maskable_icon
  validates_attachment_content_type  :small_maskable_icon,
                    content_type: ['image/jpeg', 'image/png']
  has_attached_file :large_maskable_icon
  validates_attachment_content_type  :large_maskable_icon,
                    content_type: ['image/jpeg', 'image/png']
  has_attached_file :apple_icon
  validates_attachment_content_type  :apple_icon,
                    content_type: ['image/jpeg', 'image/png']
  has_attached_file :masked_icon
  validates_attachment_content_type  :masked_icon,
                    content_type: ['image/jpeg', 'image/png']
  has_attached_file :tile_image
  validates_attachment_content_type  :tile_image,
                    content_type: ['image/jpeg', 'image/png']
  has_attached_file :er_sm_logo
  validates_attachment_content_type  :er_sm_logo,
                    content_type: ['image/jpeg', 'image/png']
  has_attached_file :large_favicon
  validates_attachment_content_type  :large_favicon,
                    content_type: ['image/jpeg', 'image/png']              
end
