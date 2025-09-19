class AddImageUploadingOptionToStructures < ActiveRecord::Migration[7.1]
  def change
    add_column :structures, :hide_image_upload_option, :boolean, default: false
  end
end
