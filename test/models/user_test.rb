require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  
  test "should process profile image upload" do
    user = users(:one)
    user.profile_image_upload = fixture_file_upload('test_image.jpg', 'image/jpeg')
    
    assert user.save
    assert user.profile_image_data.present?
    assert user.profile_image_filename.present?
    assert user.profile_image_content_type == 'image/jpeg'
    assert user.profile_image_size > 0
    assert user.profile_image_checksum.present?
  end
  
  test "should generate unique filename" do
    user = users(:one)
    filename = user.send(:generate_unique_filename, 'test.jpg')
    
    assert filename.start_with?('profile_')
    assert filename.include?('.jpg')
    assert filename.length > 20
  end
  
  test "should encode and decode image data" do
    user = users(:one)
    original_data = "test image data"
    encoded = user.send(:encode_image_data, original_data)
    decoded = user.send(:decode_image_data, encoded)
    
    assert_equal original_data, decoded
  end
  
  test "should return correct image url" do
    user = users(:one)
    user.profile_image_data = "test data"
    
    assert_equal "/users/#{user.id}/profile_image", user.img_url
  end
  
  test "should check profile image presence" do
    user = users(:one)
    assert_not user.profile_image_present?
    
    user.profile_image_data = "test data"
    assert user.profile_image_present?
  end
end
