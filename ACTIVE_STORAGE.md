# Active Storage Integration

The `imagekit-rails` gem provides integration with Active Storage, allowing you to store uploaded files directly in ImageKit and use them with ImageKit's transformation features.

## Important Limitations

Before using Active Storage with ImageKit, please be aware of these limitations:

### 1. **No Direct Browser Uploads**
Active Storage's built-in "Direct Upload" feature (browser-to-storage uploads) is **not supported** with ImageKit. 

- **Why**: Active Storage's JavaScript uses HTTP PUT requests with raw binary data, but ImageKit's API requires HTTP POST with multipart/form-data.
- **Impact**: All file uploads must go through your Rails server (standard Active Storage workflow).
- **Workaround**: Use standard file uploads as shown in this guide. For advanced use cases, you can implement custom JavaScript using ImageKit's Upload API directly.

### 2. **Variants Are Not Supported**
Active Storage's built-in variant processing (e.g., `variant(resize_to_limit: [100, 100])`) should **not be used** with ImageKit.

- **Why**: Active Storage variants trigger server-side image processing and generate URLs like `/rails/active_storage/representations/...`, which results in errors when using ImageKit as storage.
- **Solution**: Use ImageKit's on-the-fly transformations via `ik_image_tag` instead (see examples below).

```erb
<%# ❌ DON'T: Use Active Storage variants %>
<%= image_tag @user.avatar.variant(resize_to_limit: [200, 200]) %>

<%# ✅ DO: Use ImageKit transformations via ik_image_tag %>
<%= ik_image_tag(@user.avatar, transformation: [{ width: 200, height: 200 }]) %>
```

### 3. **File Deletion Not Implemented**
Files are **not automatically deleted** from ImageKit when you call `purge` or `purge_later`.

- **Why**: ImageKit's deletion API requires a `file_id`, which Active Storage doesn't track.
- **Impact**: Calling `@user.avatar.purge` will remove the database record but leave the file in ImageKit.
- **Solution**: Manually delete files from the [ImageKit Media Library](https://imagekit.io/dashboard/media-library) or use the ImageKit API directly.

### 4. **File Existence Checking Limited**
The `exist?` method always returns `true` after upload.

- **Why**: ImageKit requires listing or searching by file_id to check existence.
- **Impact**: Active Storage won't detect if a file was manually deleted from ImageKit.
- **Solution**: Files are validated during download; missing files will raise errors at that point.

## When to Use Active Storage with ImageKit

✅ **Good use cases:**
- Standard file uploads through Rails forms
- Leveraging Active Storage's model associations (`has_one_attached`, `has_many_attached`)
- Using ImageKit's on-the-fly transformations via `ik_image_tag`
- Migrating from local/S3 storage to ImageKit

❌ **Not recommended for:**
- Applications requiring browser-to-storage direct uploads
- Heavy use of Active Storage variants
- Applications requiring automatic file deletion

## Configuration

### 1. Configure ImageKit credentials

First, configure your ImageKit credentials in `config/initializers/imagekit.rb`:

```ruby
Imagekit::Rails.configure do |config|
  config.public_key = ENV['IMAGEKIT_PUBLIC_KEY']
  config.private_key = ENV['IMAGEKIT_PRIVATE_KEY']
  config.url_endpoint = ENV['IMAGEKIT_URL_ENDPOINT']
end
```

### 2. Configure storage.yml

Add ImageKit as a storage service in `config/storage.yml`:

```yaml
imagekit:
  service: ImageKit
```

The service will automatically use the credentials from your initializer configuration.

### 3. Set Active Storage service

In your environment files (`config/environments/production.rb`, etc.):

```ruby
config.active_storage.service = :imagekit
```

Or for development/test:

```ruby
# config/environments/development.rb
config.active_storage.service = :local # Use local storage in development

# config/environments/production.rb
config.active_storage.service = :imagekit # Use ImageKit in production
```

## Usage

### Basic File Uploads

All uploads go through your Rails server (standard Active Storage workflow):

```ruby
# In your model
class User < ApplicationRecord
  has_one_attached :avatar
  has_many_attached :photos
end

# In your controller
def create
  @user = User.new(user_params)
  @user.avatar.attach(params[:avatar])
  @user.save
end

private

def user_params
  params.require(:user).permit(:name, :email, :avatar)
end
```

### Displaying Images with Transformations

**Important**: Always use `ik_image_tag` instead of Rails' `image_tag` to leverage ImageKit's transformations:

```erb
<%# Basic usage - serves original image %>
<%= ik_image_tag(@user.avatar, alt: "User Avatar") %>

<%# With transformations (recommended) %>
<%= ik_image_tag(
  @user.avatar,
  transformation: [{ width: 200, height: 200, crop: :thumb }],
  alt: "User Avatar"
) %>

<%# Responsive images with transformations %>
<%= ik_image_tag(
  @user.avatar,
  transformation: [{ width: 800 }],
  sizes: "(max-width: 600px) 100vw, 800px",
  alt: "User Avatar"
) %>

<%# Multiple photos %>
<% @user.photos.each do |photo| %>
  <%= ik_image_tag(photo, transformation: [{ width: 300, height: 300, crop: :fill }]) %>
<% end %>
```

**Why `ik_image_tag`?**
- Generates ImageKit URLs with transformations
- Supports all ImageKit transformation parameters
- No server-side image processing needed
- Transformations happen on-the-fly via ImageKit's CDN

### Common Transformation Examples

```erb
<%# Resize to fit within dimensions %>
<%= ik_image_tag(@photo, transformation: [{ width: 400, height: 300 }]) %>

<%# Crop to exact dimensions %>
<%= ik_image_tag(@photo, transformation: [{ width: 400, height: 300, crop: :fill }]) %>

<%# Thumbnail with face detection %>
<%= ik_image_tag(@photo, transformation: [{ width: 200, height: 200, crop: :thumb }]) %>

<%# Apply effects %>
<%= ik_image_tag(@photo, transformation: [{ 
  width: 400, 
  effect_gray: true, 
  quality: 80 
}]) %>

<%# Chain multiple transformations %>
<%= ik_image_tag(@photo, transformation: [
  { width: 400, height: 400, crop: :fill },
  { effect_sharpen: 100 },
  { quality: 90 }
]) %>
```

See the [ImageKit Transformation Documentation](https://docs.imagekit.io/features/image-transformations) for all available options.

### Displaying Videos

The `ik_video_tag` helper works with video attachments:

```erb
<%= ik_video_tag(@post.video, controls: true, width: 640) %>

<%# With transformations %>
<%= ik_video_tag(
  @post.video,
  transformation: [{ width: 640, height: 480 }],
  controls: true,
  poster: ik_image_tag(@post.video_thumbnail)
) %>
```

### Using Attachment Methods

Active Storage attachments gain additional ImageKit methods:

```ruby
# In your views or controllers
@user.avatar.imagekit_url
# => "https://ik.imagekit.io/your_id/xyz123abc456/avatar.jpg"

# With transformations
@user.avatar.imagekit_url(transformation: [{ width: 200, height: 200 }])
# => "https://ik.imagekit.io/your_id/xyz123abc456/avatar.jpg?tr=w-200,h-200"

# Signed URLs
@user.avatar.imagekit_url(signed: true, expires_in: 3600)

# Responsive attributes
attrs = @user.avatar.imagekit_responsive_attributes(width: 800)
# => { src: "...", srcset: "... 640w, ... 750w, ...", sizes: "100vw" }
```

## Form Uploads

### Standard File Upload (Recommended)

All file uploads go through your Rails server:

```erb
<%= form_with model: @user do |f| %>
  <%= f.label :avatar %>
  <%= f.file_field :avatar %>
  <%= f.submit %>
<% end %>
```

### Multiple File Upload

```erb
<%= form_with model: @post do |f| %>
  <%= f.label :images, "Upload Images" %>
  <%= f.file_field :images, multiple: true %>
  <%= f.submit %>
<% end %>
```

**Note**: Direct browser-to-ImageKit uploads are not supported due to API incompatibility with Active Storage's DirectUpload JavaScript (which uses PUT requests, while ImageKit requires POST multipart/form-data).

## File Management

### Check if File Exists

```ruby
@user.avatar.attached? # => true/false
```

### Get File Information

```ruby
@user.avatar.blob.filename      # => "avatar.jpg"
@user.avatar.blob.content_type  # => "image/jpeg"
@user.avatar.blob.byte_size     # => 52341
```

### Delete Files

**⚠️ Important Limitation**: File deletion is **not implemented** in the ImageKit Active Storage service.

```ruby
# ❌ This only removes the Active Storage database record
# The file remains in ImageKit
@user.avatar.purge        # Delete attachment immediately
@user.avatar.purge_later  # Delete attachment in background job
```

**To fully delete files from ImageKit:**

1. **Manual deletion**: Use the [ImageKit Media Library](https://imagekit.io/dashboard/media-library) dashboard
2. **API deletion**: Use ImageKit's API directly with the file_id

```ruby
# Example: Delete via ImageKit API (you'll need the file_id)
# Note: Active Storage doesn't track file_id, so you'll need to search for it first

# This is a workaround - not built into the gem
imagekit_client = Imagekit::Client.new(private_key: ENV['IMAGEKIT_PRIVATE_KEY'])

# Search for the file by path to get its file_id
file_path = @user.avatar.key  # e.g., "uploads/abc123xyz/avatar.jpg"
# Then use ImageKit's search/list API to find the file_id
# Finally delete: imagekit_client.files.delete(file_id: file_id)
```

**Why this limitation exists**: ImageKit requires a `file_id` for deletion, but Active Storage only tracks a `key` (file path). Future versions may implement automatic file_id tracking.

## Advanced Usage

### Understanding Active Storage Variants vs ImageKit Transformations

**Active Storage Variants** (❌ Don't use with ImageKit):
```erb
<%# This creates a server-side processed variant %>
<%# URLs like /rails/active_storage/representations/... %>
<%# Results in 500 errors with ImageKit storage %>
<%= image_tag @user.avatar.variant(resize_to_limit: [200, 200]) %>
```

**ImageKit Transformations** (✅ Use this instead):
```erb
<%# This applies transformations on-the-fly via ImageKit's CDN %>
<%# URLs like https://ik.imagekit.io/your_id/path?tr=w-200,h-200 %>
<%# No server processing, instant transformations %>
<%= ik_image_tag(@user.avatar, transformation: [{ width: 200, height: 200 }]) %>
```

**Why ImageKit transformations are better:**
- ✅ No server-side processing required
- ✅ Transformations applied on-the-fly by ImageKit's CDN
- ✅ Cached globally for fast delivery
- ✅ Support for advanced features (smart crop, quality optimization, format conversion)
- ✅ Original file is never modified

### Common Migration Pattern from Variants

If you're migrating from local/S3 storage with variants, here's how to convert:

```erb
<%# Before (with local/S3 storage) %>
<%= image_tag @photo.variant(resize_to_fill: [400, 300]) %>
<%= image_tag @photo.variant(resize_to_limit: [800, 600]) %>
<%= image_tag @avatar.variant(resize_and_pad: [200, 200, background: [255, 255, 255]]) %>

<%# After (with ImageKit) %>
<%= ik_image_tag(@photo, transformation: [{ width: 400, height: 300, crop: :fill }]) %>
<%= ik_image_tag(@photo, transformation: [{ width: 800, height: 600 }]) %>
<%= ik_image_tag(@avatar, transformation: [{ 
  width: 200, 
  height: 200, 
  crop: :pad_resize,
  background: 'FFFFFF'
}]) %>
```

### File Organization

Active Storage automatically generates unique keys for uploaded files. These keys determine the file path in ImageKit. For example, Active Storage might generate a key like `abc123xyz456`, which will be stored in ImageKit at that path.

To organize files in specific folders, you can customize Active Storage's key generation. See [Active Storage documentation](https://edgeguides.rubyonrails.org/active_storage_overview.html) for details.

### Multiple Attachments

```ruby
class Post < ApplicationRecord
  has_many_attached :images
end

# Upload multiple files
@post.images.attach(params[:images])

# Display all images with transformations
<% @post.images.each do |image| %>
  <%= ik_image_tag(image, transformation: [{ width: 400, crop: :fill }]) %>
<% end %>
```

## Testing

### In Tests

Use local storage in test environment:

```ruby
# config/environments/test.rb
config.active_storage.service = :local
```

Or use ImageKit for testing (files will be uploaded to ImageKit):

```yaml
# config/storage.yml
imagekit_test:
  service: ImageKit
```

**Note:** Consider using local storage for tests to avoid unnecessary API calls and costs.

## Troubleshooting

### Files Not Uploading

1. Verify your ImageKit credentials are correct in `config/initializers/imagekit.rb`
2. Check that `public_key`, `private_key`, and `url_endpoint` are set
3. Ensure your ImageKit account has upload permissions
4. Check Rails logs for specific error messages

### URLs Not Generating or Showing Errors

1. **Issue**: Seeing 500 errors or `/rails/active_storage/representations/...` URLs
   - **Cause**: Using `image_tag` with `.variant()` instead of `ik_image_tag`
   - **Solution**: Replace all `image_tag @attachment.variant(...)` with `ik_image_tag(@attachment, transformation: [...])`

2. **Issue**: `url_endpoint` not configured
   - **Cause**: Missing configuration in `config/initializers/imagekit.rb`
   - **Solution**: Verify all three credentials are set (public_key, private_key, url_endpoint)

3. **Issue**: Image not attached
   - **Cause**: Calling `ik_image_tag` on unattached file
   - **Solution**: Check `@user.avatar.attached?` before displaying

### Performance Optimization

- Use `ik_image_tag` with transformations instead of serving original files
- Enable CDN caching in your ImageKit dashboard
- Use responsive images with `srcset` for optimal performance:
  ```erb
  <%= ik_image_tag(@photo, 
    transformation: [{ width: 800 }],
    sizes: "(max-width: 600px) 100vw, 800px"
  ) %>
  ```
- Use background jobs for large file uploads (standard Rails practice)
- Apply format optimization:
  ```erb
  <%= ik_image_tag(@photo, transformation: [{ 
    width: 800, 
    format: :auto,  # Automatically serve WebP where supported
    quality: 80 
  }]) %>
  ```

## Known Limitations Summary

### Critical Limitations

1. **❌ No Direct Browser Uploads**
   - Active Storage's DirectUpload JavaScript is not compatible with ImageKit's API
   - Reason: DirectUpload uses PUT with raw binary; ImageKit requires POST with multipart/form-data
   - Workaround: Use standard file uploads through Rails server (shown in this guide)

2. **❌ No Variant Support**
   - Do not use `.variant()` methods with ImageKit storage
   - Reason: Variants create Rails-processed representations that fail with ImageKit URLs
   - Solution: Use `ik_image_tag` with `transformation:` parameter instead
   - Example: Replace `image_tag @photo.variant(resize: "100x100")` with `ik_image_tag(@photo, transformation: [{ width: 100, height: 100 }])`

3. **❌ File Deletion Not Implemented**
   - `purge` and `purge_later` only remove database records
   - Reason: ImageKit requires file_id for deletion, Active Storage only tracks keys
   - Solution: Manually delete from ImageKit dashboard or use ImageKit API

4. **⚠️ File Existence Check Limited**
   - `exist?` always returns true after upload
   - Reason: ImageKit requires listing/searching to verify existence
   - Impact: Missing files detected only during download

### Recommended Workflow

✅ **What works great:**
- Standard file uploads through Rails forms
- Active Storage model associations (`has_one_attached`, `has_many_attached`)
- Displaying images with `ik_image_tag` and transformations
- All ImageKit transformation features (resize, crop, effects, quality, format)
- Responsive images with srcset
- File downloads and streaming

❌ **What doesn't work:**
- Direct browser-to-ImageKit uploads
- Active Storage variants (`.variant()`, `resize_to_limit`, etc.)
- Automatic file deletion from ImageKit
- Real-time file existence verification

### Comparison with Other Storage Services

| Feature | Local/S3 Storage | ImageKit Storage |
|---------|-----------------|------------------|
| File Upload | ✅ Through server | ✅ Through server |
| Direct Upload | ✅ Supported | ❌ Not supported |
| Variants | ✅ Server processing | ❌ Use transformations |
| Image Transformations | ❌ Requires processing | ✅ On-the-fly CDN |
| File Deletion | ✅ Automatic | ❌ Manual |
| File Existence | ✅ Real-time | ⚠️ Limited |
| CDN Delivery | ⚠️ Requires setup | ✅ Built-in |
| Format Optimization | ❌ Manual | ✅ Automatic |

## Migration from Other Storage

To migrate existing Active Storage files to ImageKit:

```ruby
# Create a migration task
# lib/tasks/migrate_to_imagekit.rake
namespace :storage do
  desc "Migrate Active Storage files from local/S3 to ImageKit"
  task migrate_to_imagekit: :environment do
    # First, backup your current storage configuration
    old_service = ActiveStorage::Blob.service
    
    # Temporarily use local/S3 to download
    # Then switch to ImageKit to upload
    
    User.find_each do |user|
      next unless user.avatar.attached?
      
      # Download from old storage
      tempfile = Tempfile.new(['avatar', File.extname(user.avatar.filename.to_s)])
      begin
        tempfile.binmode
        user.avatar.download do |chunk|
          tempfile.write(chunk)
        end
        tempfile.rewind
        
        # Store original metadata
        filename = user.avatar.blob.filename
        content_type = user.avatar.blob.content_type
        
        # Remove old attachment
        user.avatar.purge
        
        # Attach to ImageKit
        user.avatar.attach(
          io: tempfile,
          filename: filename,
          content_type: content_type
        )
        
        puts "Migrated avatar for user #{user.id}"
      ensure
        tempfile.close
        tempfile.unlink
      end
    end
  end
end
```

**Important:** 
- Run this in a background job for production
- Test thoroughly on staging first
- Consider keeping old storage as backup initially
- Update `config/storage.yml` to use `:imagekit` after migration
- Note that files deleted from Active Storage will remain in ImageKit

Run with: `rails storage:migrate_to_imagekit`
