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
<!-- Don't do this: -->
<%= image_tag @user.avatar.variant(resize_to_limit: [200, 200]) %>

<!-- Do this instead: -->
<%= ik_image_tag(@user.avatar, transformation: [{ width: 200, height: 200 }]) %>
```

## When to Use Active Storage with ImageKit

**Good use cases:**
- Standard file uploads through Rails forms
- Leveraging Active Storage's model associations (`has_one_attached`, `has_many_attached`)
- Using ImageKit's on-the-fly transformations via `ik_image_tag`
- Migrating from local/S3 storage to ImageKit
- Automatic file deletion when purging attachments

**Not recommended for:**
- Applications requiring browser-to-storage direct uploads
- Heavy use of Active Storage variants

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

Always use `ik_image_tag` instead of Rails' `image_tag` to leverage ImageKit's transformations:

```erb
<!-- Basic usage -->
<%= ik_image_tag(@user.avatar, alt: "User Avatar") %>

<!-- With transformations -->
<%= ik_image_tag(
  @user.avatar,
  transformation: [{ width: 200, height: 200, crop: :thumb }],
  alt: "User Avatar"
) %>

<!-- Responsive images -->
<%= ik_image_tag(
  @user.avatar,
  transformation: [{ width: 800 }],
  sizes: "(max-width: 600px) 100vw, 800px",
  alt: "User Avatar"
) %>

<!-- Multiple photos -->
<% @user.photos.each do |photo| %>
  <%= ik_image_tag(photo, transformation: [{ width: 300, height: 300, crop: :fill }]) %>
<% end %>
```

Common transformations:

```erb
<!-- Resize -->
<%= ik_image_tag(@photo, transformation: [{ width: 400, height: 300 }]) %>

<!-- Crop to exact dimensions -->
<%= ik_image_tag(@photo, transformation: [{ width: 400, height: 300, crop: :fill }]) %>

<!-- Effects -->
<%= ik_image_tag(@photo, transformation: [{ 
  width: 400, 
  effect_gray: true, 
  quality: 80 
}]) %>

<!-- Chain multiple transformations -->
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

<!-- With transformations -->
<%= ik_video_tag(
  @post.video,
  transformation: [{ width: 640, height: 480 }],
  controls: true
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

Files are automatically deleted from ImageKit when you purge attachments:

```ruby
@user.avatar.purge        # Removes file from ImageKit and DB record
@user.avatar.purge_later  # Same, but in background job
```

You can also configure dependent deletion in your models:

```ruby
class User < ApplicationRecord
  has_one_attached :avatar, dependent: :purge_later
  has_many_attached :photos, dependent: :purge_later
end

# When user is destroyed, all attachments are purged automatically
@user.destroy
```

## Advanced Usage

### Migrating from Variants

If you're migrating from local/S3 storage and using variants, convert them to ImageKit transformations:

```erb
<!-- Before (local/S3 storage with variants) -->
<%= image_tag @photo.variant(resize_to_fill: [400, 300]) %>
<%= image_tag @photo.variant(resize_to_limit: [800, 600]) %>
<%= image_tag @avatar.variant(resize_and_pad: [200, 200, background: [255, 255, 255]]) %>

<!-- After (ImageKit transformations) -->
<%= ik_image_tag(@photo, transformation: [{ width: 400, height: 300, crop: :fill }]) %>
<%= ik_image_tag(@photo, transformation: [{ width: 800, height: 600 }]) %>
<%= ik_image_tag(@avatar, transformation: [{ 
  width: 200, 
  height: 200, 
  crop: :pad_resize,
  background: 'FFFFFF'
}]) %>
```

### Custom File Organization

The service uses the Active Storage `key` as the complete file path in ImageKit, extracting the folder path with `File.dirname(key)` and filename with `File.basename(key)`. To organize files in specific folders, set a custom key when attaching:

```ruby
# In your controller
def create
  @post = Post.new(post_params.except(:image))
  
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

- Backup your database (especially `active_storage_blobs` table)
- Test on staging environment first
- Verify ImageKit credentials in `config/initializers/imagekit.rb`
- Add ImageKit service to `config/storage.yml`
- Ensure sufficient disk space for temp files

**During Migration:**

- Run during low-traffic period
- Monitor output for errors
- Check Rails logs for detailed error messages
- Use `screen` or `tmux` to keep session active

**After Migration:**

- Verify images load correctly in your app
- Test new uploads go to ImageKit
- Confirm blobs have `service_name: 'imagekit'` in database
- Keep old storage for at least 1-2 weeks
- Update `config.active_storage.service = :imagekit` if not already set

### How It Works

- Migrates all attachments across all models automatically (blob-level)
- Preserves file paths by using the same `key`
- Handles errors gracefully - one failure doesn't stop migration
- Old files remain as backup - only database pointer changes
- Resumable - re-run to migrate remaining blobs if interrupted

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
