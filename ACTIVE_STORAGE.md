# Active Storage Integration

The `imagekit-rails` gem provides seamless integration with Active Storage, allowing you to store uploaded files directly in ImageKit and use them with all ImageKit features.

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

### Displaying Images

The `ik_image_tag` helper automatically works with Active Storage attachments:

```erb
<%# Basic usage %>
<%= ik_image_tag(@user.avatar, alt: "User Avatar") %>

<%# With transformations %>
<%= ik_image_tag(
  @user.avatar,
  transformation: [{ width: 200, height: 200, crop: :thumb }],
  alt: "User Avatar"
) %>

<%# With responsive images %>
<%= ik_image_tag(
  @user.avatar,
  width: 800,
  sizes: "(max-width: 600px) 100vw, 800px",
  alt: "User Avatar"
) %>

<%# For has_many_attached %>
<% @user.photos.each do |photo| %>
  <%= ik_image_tag(photo, transformation: [{ width: 300 }], alt: "Photo") %>
<% end %>
```

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

### Simple File Upload

```erb
<%= form_with model: @user do |f| %>
  <%= f.label :avatar %>
  <%= f.file_field :avatar %>
  <%= f.submit %>
<% end %>
```

### Direct Upload (Browser to ImageKit)

**Note:** Direct uploads from browser to ImageKit require additional setup and are currently under development. For now, uploads go through your Rails server.

Standard file upload (recommended):

```erb
<%= form_with model: @user do |f| %>
  <%= f.label :avatar %>
  <%= f.file_field :avatar %>
  <%= f.submit %>
<% end %>
```

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

**Important Note:** File deletion is currently not implemented in the ImageKit Active Storage service. When you call `purge` or `purge_later`, Active Storage will remove the database record, but the file will remain in ImageKit.

```ruby
# Removes the attachment record, but file stays in ImageKit
@user.avatar.purge        # Delete attachment immediately
@user.avatar.purge_later  # Delete attachment in background job
```

**To fully delete files:**
- Manually delete files from your [ImageKit Media Library](https://imagekit.io/dashboard/media-library)
- Or use the ImageKit API directly to delete files by their file_id

This limitation exists because ImageKit's deletion API requires a `file_id`, which Active Storage doesn't track. A future version may implement file deletion by searching for files first.

## Advanced Usage

### File Organization

Active Storage automatically generates unique keys for uploaded files. These keys determine the file path in ImageKit. For example, Active Storage might generate a key like `variants/abc123xyz456/thumbnail.jpg`, which will be stored in ImageKit at that exact path.

If you want to organize files in specific folders, you can customize Active Storage's key generation. See [Active Storage documentation](https://edgeguides.rubyonrails.org/active_storage_overview.html) for details on customizing storage paths.

### Variants (Active Storage Processing)

While Active Storage supports variants, with ImageKit you can apply transformations on-the-fly:

```erb
<%# Instead of Active Storage variants %>
<%= image_tag @user.avatar.variant(resize_to_limit: [200, 200]) %>

<%# Use ImageKit transformations (no processing needed) %>
<%= ik_image_tag(@user.avatar, transformation: [{ width: 200, height: 200 }]) %>
```

### Multiple Attachments

```ruby
class Post < ApplicationRecord
  has_many_attached :images
end

# Upload multiple files
@post.images.attach(params[:images])

# Display all images
<% @post.images.each do |image| %>
  <%= ik_image_tag(image, transformation: [{ width: 400 }]) %>
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
2. Check that `public_key`, `private_key`, and `url_endpoint` are set in the initializer
3. Ensure your ImageKit account has upload permissions
4. Check Rails logs for specific error messages

### URLs Not Generating

1. Verify `url_endpoint` is configured in `config/initializers/imagekit.rb`
2. Check that the attachment is actually attached: `@user.avatar.attached?`
3. Ensure the ImageKit service is properly configured in `storage.yml`
4. Verify the imagekit gem is properly loaded

### Performance

- Use standard uploads (files go through your Rails server)
- Enable CDN caching in your ImageKit dashboard
- Use responsive images with `srcset` for optimal performance
- Consider background jobs for large file uploads

### Known Limitations

- **File Deletion**: Files are not automatically deleted from ImageKit when calling `purge` or `purge_later`. Files must be manually deleted from ImageKit dashboard or via the ImageKit API.
- **Direct uploads**: Browser-to-ImageKit direct uploads are not yet fully implemented
- **Streaming**: Large file streaming uses full download (not chunked streaming)
- **Public URLs**: All URLs go through ImageKit's CDN (use transformations for optimization)

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
