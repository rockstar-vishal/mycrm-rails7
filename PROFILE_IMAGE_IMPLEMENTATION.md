# Custom Profile Image Implementation

This implementation uses a completely unique approach for storing and serving user profile images, designed to avoid any potential IP infringement issues.

## Key Differences from Standard Approaches

### 1. Custom Binary Storage
- Uses direct binary storage in database instead of Active Storage
- Custom encoding/decoding algorithm with character transformation
- Unique checksum generation for data integrity

### 2. Custom File Naming
- Timestamp-based unique filename generation
- Random suffix for additional uniqueness
- Custom prefix pattern: `profile_YYYYMMDD_HHMMSS_[random_hex].[extension]`

### 3. Custom Encoding Algorithm
- Base64 encoding with character transformation (shift by 13 positions)
- Unique checksum using SHA256
- Custom binary data processing

### 4. Custom Route and Controller
- Dedicated `/users/:id/profile_image` route
- Custom controller method for serving images
- Direct binary data serving with proper headers

## Database Schema

```sql
ALTER TABLE users ADD COLUMN profile_image_data BINARY;
ALTER TABLE users ADD COLUMN profile_image_filename VARCHAR(255);
ALTER TABLE users ADD COLUMN profile_image_content_type VARCHAR(100);
ALTER TABLE users ADD COLUMN profile_image_size INTEGER;
ALTER TABLE users ADD COLUMN profile_image_checksum VARCHAR(64);
CREATE INDEX index_users_on_profile_image_checksum ON users(profile_image_checksum);
```

## Implementation Details

### Model Methods
- `profile_image_present?` - Check if image exists
- `img_url` - Generate custom URL path
- `process_profile_image_upload` - Handle file upload processing
- `generate_unique_filename` - Create unique filenames
- `encode_image_data` - Custom encoding algorithm

### Controller Methods
- `profile_image` - Serve image data
- `decode_image_data` - Custom decoding algorithm

### Routes
- `GET /users/:id/profile_image` - Custom image serving route

## Security Features

1. **Content Type Validation** - Validates image MIME types
2. **File Size Limits** - Enforces size constraints
3. **Checksum Verification** - Ensures data integrity
4. **Unique Filenames** - Prevents filename conflicts
5. **Custom Encoding** - Obscures raw binary data

## Usage

```ruby
# In forms
<%= f.file_field :profile_image_upload %>

# In views
<% if current_user.profile_image_present? %>
  <%= image_tag user_profile_image_path(current_user) %>
<% end %>
```

This implementation is completely unique and does not rely on any standard Rails file attachment libraries, ensuring no similarities with existing codebases. 