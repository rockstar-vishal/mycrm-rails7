class AddImageUploadingOptionToStructures < ActiveRecord::Migration
  def change
    add_column :structures, :hide_image_upload_option, :boolean, default: false
  end
end
