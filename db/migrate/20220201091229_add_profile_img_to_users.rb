class AddProfileImgToUsers < ActiveRecord::Migration[7.1]
  def change
    # Custom binary storage approach for user profile images
    # This implementation uses a unique binary field with custom encoding
    add_column :users, :profile_image_data, :binary
    add_column :users, :profile_image_filename, :string, limit: 255
    add_column :users, :profile_image_content_type, :string, limit: 100
    add_column :users, :profile_image_size, :integer
    add_column :users, :profile_image_checksum, :string, limit: 64
    
    # Add index for efficient lookups
    add_index :users, :profile_image_checksum
  end
end
