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

To migrate existing Active Storage files from local/S3/GCS to ImageKit, use a blob-level migration that preserves file paths and handles errors gracefully.

### Migration Task

Create `lib/tasks/migrate_to_imagekit.rake`:

```ruby
namespace :storage do
  desc "Migrate Active Storage files from local/S3/GCS to ImageKit"
  task migrate_to_imagekit: :environment do
    require 'tempfile'
    
    # Configuration
    old_service_name = ENV.fetch('OLD_SERVICE', 'local')  # or 's3', 'google', etc.
    new_service_name = 'imagekit'
    
    # Get service instances
    old_service = ActiveStorage::Blob.services.fetch(old_service_name.to_sym)
    new_service = ActiveStorage::Blob.services.fetch(new_service_name.to_sym)
    
    puts "Migrating from #{old_service_name} to #{new_service_name}..."
    puts "Total blobs to migrate: #{ActiveStorage::Blob.where(service_name: old_service_name).count}"
    
    # Migrate all blobs from old service
    ActiveStorage::Blob.where(service_name: old_service_name).find_each do |blob|
      print "Migrating blob #{blob.id} (#{blob.filename})... "
      
      begin
        # Create temp file with proper extension
        tempfile = Tempfile.new(
          ['migration', File.extname(blob.filename.to_s)],
          binmode: true
        )
        
        # Download from old service
        old_service.download(blob.key) do |chunk|
          tempfile.write(chunk)
        end
        tempfile.rewind
        
        # Upload to new service with same key (preserves file paths)
        new_service.upload(
          blob.key,
          tempfile,
          checksum: blob.checksum,
          filename: blob.filename.to_s
        )
        
        # Update blob record to point to new service
        blob.update!(service_name: new_service_name)
        
        puts "✅ Success"
        
      rescue StandardError => e
        puts "❌ Failed: #{e.message}"
        # Log error but continue with next blob
        Rails.logger.error "Migration failed for blob #{blob.id}: #{e.message}\n#{e.backtrace.join("\n")}"
      ensure
        # Always clean up temp file
        if tempfile
          tempfile.close
          tempfile.unlink
        end
      end
    end
    
    puts "\n" + "="*50
    puts "Migration complete!"
    puts "Migrated: #{ActiveStorage::Blob.where(service_name: new_service_name).count} blobs"
    puts "Remaining in #{old_service_name}: #{ActiveStorage::Blob.where(service_name: old_service_name).count} blobs"
    puts "\nNote: Old files remain in #{old_service_name} storage."
    puts "Verify all files work correctly before deleting old storage."
    puts "="*50
  end
end
```

### Usage

```bash
# Set the old service name (default: 'local')
OLD_SERVICE=local rails storage:migrate_to_imagekit

# Or for S3
OLD_SERVICE=amazon rails storage:migrate_to_imagekit

# Or for Google Cloud Storage
OLD_SERVICE=google rails storage:migrate_to_imagekit
```

### Migration Checklist

**Before Migration:**

1. ✅ **Backup your database** - Keep a copy of the `active_storage_blobs` table
2. ✅ **Test on staging** - Run migration on a staging environment first
3. ✅ **Verify credentials** - Ensure ImageKit credentials are correct in `config/initializers/imagekit.rb`
4. ✅ **Check storage.yml** - Add ImageKit service configuration
5. ✅ **Monitor space** - Ensure you have enough disk space for temp files during migration

**During Migration:**

1. Run during low-traffic period
2. Monitor the output for errors
3. Check Rails logs for detailed error messages
4. Keep the terminal session active (or use `screen`/`tmux`)

**After Migration:**

1. ✅ **Verify files** - Check that images load correctly in your app
2. ✅ **Test uploads** - Verify new uploads go to ImageKit
3. ✅ **Check database** - Confirm blobs have `service_name: 'imagekit'`
4. ✅ **Keep old storage** - Don't delete old files for at least 1-2 weeks
5. ✅ **Update config** - Set `config.active_storage.service = :imagekit` if not already

### How It Works

1. **Blob-level migration**: Migrates all attachments across all models automatically
2. **Preserves file paths**: Uses the same `key` so URLs remain consistent
3. **Error handling**: One failure doesn't stop the entire migration
4. **Safe approach**: Old files remain as backup; only the database pointer changes
5. **Resumable**: If interrupted, re-run to migrate remaining blobs

### Verifying Migration

After migration, verify that files are accessible:

```ruby
# In Rails console
blob = ActiveStorage::Blob.first
blob.service_name  # Should be "imagekit"

# Download test
blob.download  # Should download from ImageKit

# URL test (if using ik_image_tag)
# In your app, check that images display correctly
```

### Rollback (If Needed)

If you need to rollback to the old storage:

```ruby
# In Rails console - switch back to old service
ActiveStorage::Blob.where(service_name: 'imagekit').update_all(service_name: 'local')

# Then update config/environments/production.rb
config.active_storage.service = :local  # or :amazon, :google, etc.
```

This works because old files are still in the old storage (not deleted).

### Cleaning Up Old Storage

After verifying everything works for 1-2 weeks:

- **Local storage**: Delete the `storage/` directory
- **S3**: Delete the bucket or folder
- **GCS**: Delete the bucket

**Important:** Only do this after thoroughly verifying all files are accessible from ImageKit!
