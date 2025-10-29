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

- **Why**: Active Storage variants trigger server-side image processing and generate URLs like `/rails/active_storage/representations/...`. When you call `.variant()`, Active Storage attempts to download the file from ImageKit, process it locally, and upload the variant back to ImageKit - this is inefficient and unnecessary.
- **Solution**: Use ImageKit's on-the-fly transformations via `ik_image_tag` instead. ImageKit applies transformations in real-time via CDN without any server processing or additional uploads.

```erb
<%# ❌ DON'T: Use Active Storage variants %>
<%# This will download from ImageKit, process on your server, and upload back %>
<%= image_tag @user.avatar.variant(resize_to_limit: [200, 200]) %>

<%# ✅ DO: Use ImageKit transformations via ik_image_tag %>
<%# This applies transformations on-the-fly via ImageKit's CDN - no processing needed %>
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
  config.public_key = ENV['IMAGEKIT_PUBLIC_KEY']      # Required for file uploads
  config.private_key = ENV['IMAGEKIT_PRIVATE_KEY']    # Required for signed URLs and client operations
  config.url_endpoint = ENV['IMAGEKIT_URL_ENDPOINT']  # Required for URL generation
end
```

### 2. Configure storage.yml

Add ImageKit as a storage service in `config/storage.yml`:

```yaml
imagekit:
  service: ImageKit
```

**Note:** By default, the service reads credentials (`url_endpoint`, `public_key`, `private_key`) from your global configuration (`config/initializers/imagekit.rb`). However, you can optionally override these credentials in `storage.yml` to use different ImageKit accounts for different environments or use cases:

```yaml
# Option 1: Use global configuration (most common)
imagekit:
  service: ImageKit

# Option 2: Override with specific credentials
imagekit_production:
  service: ImageKit
  private_key: <%= ENV['IMAGEKIT_PRODUCTION_PRIVATE_KEY'] %>
  public_key: <%= ENV['IMAGEKIT_PRODUCTION_PUBLIC_KEY'] %>
  url_endpoint: <%= ENV['IMAGEKIT_PRODUCTION_URL_ENDPOINT'] %>

imagekit_staging:
  service: ImageKit
  private_key: <%= ENV['IMAGEKIT_STAGING_PRIVATE_KEY'] %>
  public_key: <%= ENV['IMAGEKIT_STAGING_PUBLIC_KEY'] %>
  url_endpoint: <%= ENV['IMAGEKIT_STAGING_URL_ENDPOINT'] %>
```

If credentials are provided in `storage.yml`, they will take precedence over the global configuration. If not provided, the service falls back to the global configuration.

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

### Checking Attachment Information

Use standard Active Storage methods to check attachment status:

```ruby
@user.avatar.attached?  # => true/false
```

### Getting URLs Programmatically

For views, use `ik_image_tag` (covered above). However, if you need raw URLs for non-view contexts (APIs, background jobs, mailers, or JSON responses), access the service directly:

```ruby
# Get URL for an attachment
url = @user.avatar.service.url(@user.avatar.blob.key)
# => "https://ik.imagekit.io/your_id/abc123xyz"

# With transformations
url = @user.avatar.service.url(
  @user.avatar.blob.key,
  transformation: [{ width: 200, height: 200 }]
)
# => "https://ik.imagekit.io/your_id/abc123xyz?tr=w-200,h-200"

# Example: In a JSON API response
def show
  render json: {
    user: {
      name: @user.name,
      avatar_url: @user.avatar.service.url(
        @user.avatar.blob.key,
        transformation: [{ width: 150, height: 150, crop: :thumb }]
      )
    }
  }
end

# Example: In a mailer
class UserMailer < ApplicationMailer
  def welcome_email(user)
    @avatar_url = user.avatar.service.url(
      user.avatar.blob.key,
      transformation: [{ width: 100, height: 100 }]
    )
    mail(to: user.email, subject: "Welcome!")
  end
end
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
<%# When you use .variant(), Active Storage will: %>
<%# 1. Download the original file from ImageKit to your server %>
<%# 2. Process it using MiniMagick/libvips on your server %>
<%# 3. Upload the processed variant BACK to ImageKit %>
<%# 4. Serve via URLs like /rails/active_storage/representations/... %>
<%# This is wasteful - it re-uploads transformed files to ImageKit! %>
<%= image_tag @user.avatar.variant(resize_to_limit: [200, 200]) %>
```

**ImageKit Transformations** (✅ Use this instead):
```erb
<%# ImageKit applies transformations on-the-fly via CDN %>
<%# No downloads, no server processing, no re-uploads %>
<%# URLs like https://ik.imagekit.io/your_id/path?tr=w-200,h-200 %>
<%# Original file stays untouched, transformations cached globally %>
<%= ik_image_tag(@user.avatar, transformation: [{ width: 200, height: 200 }]) %>
```

**Why ImageKit transformations are better:**
- ✅ No server-side processing required
- ✅ No redundant file uploads to ImageKit
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

Active Storage automatically generates unique keys for uploaded files. The service uses these keys as the complete file path in ImageKit:

**How it works:**
1. Active Storage generates a key (e.g., `abc123xyz456`)
2. The service extracts the folder path using `File.dirname(key)` (e.g., `.` for root or `folder/subfolder`)
3. The service extracts the filename using `File.basename(key)` (e.g., `abc123xyz456` or `image.jpg`)
4. The file is uploaded to ImageKit at that path

**Customizing folder structure:**
You can set a custom key when attaching files to organize them in specific folders:

```ruby
# In your controller
def create
  @post = Post.new(post_params.except(:image))
  
  # Attach with custom key for folder organization
  if params[:post][:image].present?
    image_file = params[:post][:image]
    custom_key = "uploads/posts/#{image_file.original_filename}"
    
    @post.image.attach(
      io: image_file,
      filename: image_file.original_filename,
      content_type: image_file.content_type,
      key: custom_key
    )
  end
  
  @post.save
end
```

This will upload the file to ImageKit at `/uploads/posts/filename.jpg`.

For more information about Active Storage, see the [Active Storage documentation](https://edgeguides.rubyonrails.org/active_storage_overview.html).

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
