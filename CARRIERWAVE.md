# CarrierWave Integration

The `imagekit-rails` gem provides a storage adapter for CarrierWave, allowing you to store uploaded files directly in ImageKit.

## Installation

Add CarrierWave to your Gemfile if you haven't already:

```ruby
gem 'carrierwave', '~> 3.0'
gem 'imagekit-rails'
```

## Configuration

### Global Configuration

Configure ImageKit in an initializer (`config/initializers/carrierwave.rb`):

```ruby
CarrierWave.configure do |config|
  config.storage = :imagekit
  
  # ImageKit credentials (optional if already configured in imagekit-rails)
  config.imagekit_url_endpoint = ENV['IMAGEKIT_URL_ENDPOINT']
  config.imagekit_public_key = ENV['IMAGEKIT_PUBLIC_KEY']
  config.imagekit_private_key = ENV['IMAGEKIT_PRIVATE_KEY']
end
```

Or use the existing `imagekit-rails` configuration:

```ruby
# config/initializers/imagekit.rb
Imagekit::Rails.configure do |config|
  config.url_endpoint = ENV['IMAGEKIT_URL_ENDPOINT']
  config.public_key = ENV['IMAGEKIT_PUBLIC_KEY']
  config.private_key = ENV['IMAGEKIT_PRIVATE_KEY']
end

# config/initializers/carrierwave.rb
CarrierWave.configure do |config|
  config.storage = :imagekit
  # Will automatically use imagekit-rails configuration
end
```

## Creating Uploaders

### Basic Uploader

```ruby
# app/uploaders/avatar_uploader.rb
class AvatarUploader < CarrierWave::Uploader::Base
  storage :imagekit
  
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end
  
  def extension_allowlist
    %w[jpg jpeg gif png]
  end
end
```

### Using in Models

```ruby
class User < ApplicationRecord
  mount_uploader :avatar, AvatarUploader
end
```

## Usage

### Uploading Files

```ruby
# In your controller
def create
  @user = User.new(user_params)
  @user.avatar = params[:avatar]
  @user.save
end

# Or
@user.avatar = File.open('path/to/file.jpg')
@user.save

# Or from URL
@user.remote_avatar_url = 'https://example.com/image.jpg'
@user.save
```

### Displaying Images

Use the `ik_image_tag` helper with CarrierWave URLs:

```erb
<%# Basic usage - will use default URL %>
<%= image_tag @user.avatar.url %>

<%# With ImageKit transformations %>
<%= ik_image_tag(
  @user.avatar.path,
  transformation: [{ width: 200, height: 200, crop: :thumb }],
  alt: "User Avatar"
) %>

<%# Or get ImageKit URL directly from uploader %>
<%= image_tag @user.avatar.url(transformation: [{ width: 200 }]) %>
```

### Getting URLs

```ruby
# Basic URL
@user.avatar.url
# => "https://ik.imagekit.io/your_id/uploads/user/avatar/1/file.jpg"

# With ImageKit transformations
@user.avatar.url(transformation: [{ width: 200, height: 200 }])
# => "https://ik.imagekit.io/your_id/uploads/user/avatar/1/file.jpg?tr=w-200,h-200"

# Signed URL
@user.avatar.url(signed: true, expires_in: 3600)
```

## Versions (Thumbnails)

While CarrierWave supports processing versions, with ImageKit you can apply transformations on-the-fly:

```ruby
# Traditional CarrierWave approach (requires processing)
class AvatarUploader < CarrierWave::Uploader::Base
  storage :imagekit
  
  version :thumb do
    process resize_to_fit: [200, 200]
  end
  
  version :small do
    process resize_to_fit: [400, 400]
  end
end

# ImageKit approach (no processing needed, on-the-fly transformations)
class AvatarUploader < CarrierWave::Uploader::Base
  storage :imagekit
  
  # No versions needed! Use transformations in views:
  # @user.avatar.url(transformation: [{ width: 200, height: 200 }])
end
```

### Using in Views

```erb
<%# Traditional versions %>
<%= image_tag @user.avatar.thumb.url %>

<%# ImageKit transformations (recommended) %>
<%= ik_image_tag(
  @user.avatar.path,
  transformation: [{ width: 200, height: 200 }],
  alt: "Thumbnail"
) %>
```

## Advanced Configuration

### Per-Uploader Configuration

Override ImageKit settings per uploader:

```ruby
class AvatarUploader < CarrierWave::Uploader::Base
  storage :imagekit
  
  def self.imagekit_url_endpoint
    'https://ik.imagekit.io/custom_endpoint'
  end
  
  def store_dir
    "avatars/#{model.id}"
  end
end
```

### Custom File Names

```ruby
class AvatarUploader < CarrierWave::Uploader::Base
  storage :imagekit
  
  def filename
    "#{secure_token}.#{file.extension}" if original_filename.present?
  end
  
  protected
  
  def secure_token
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) || model.instance_variable_set(var, SecureRandom.uuid)
  end
end
```

### Conditional Storage

Use different storage based on environment:

```ruby
class AvatarUploader < CarrierWave::Uploader::Base
  if Rails.env.production?
    storage :imagekit
  else
    storage :file
  end
end
```

## File Management

### Check if File Exists

```ruby
@user.avatar? # => true/false
@user.avatar.file.exists? # => true/false
```

### Get File Information

```ruby
@user.avatar.filename         # => "avatar.jpg"
@user.avatar.content_type     # => "image/jpeg"
@user.avatar.size             # => 52341
@user.avatar.file.extension   # => "jpg"
```

### Delete Files

```ruby
@user.remove_avatar!
@user.save
```

## Form Helpers

### Simple Upload Form

```erb
<%= form_with model: @user do |f| %>
  <%= f.label :avatar %>
  <%= f.file_field :avatar %>
  
  <% if @user.avatar? %>
    Current: <%= image_tag @user.avatar.url(transformation: [{ width: 100 }]) %>
    <%= f.check_box :remove_avatar %>
    <%= f.label :remove_avatar, "Remove avatar" %>
  <% end %>
  
  <%= f.submit %>
<% end %>
```

### Multiple File Upload

```ruby
class Post < ApplicationRecord
  mount_uploaders :images, ImageUploader
  serialize :images, JSON # or use JSONB column type
end
```

```erb
<%= form_with model: @post do |f| %>
  <%= f.label :images %>
  <%= f.file_field :images, multiple: true %>
  <%= f.submit %>
<% end %>
```

## Validation

```ruby
class AvatarUploader < CarrierWave::Uploader::Base
  storage :imagekit
  
  def extension_allowlist
    %w[jpg jpeg gif png webp]
  end
  
  def content_type_allowlist
    /image\//
  end
  
  def size_range
    1..10.megabytes
  end
end
```

## Background Processing

### With Sidekiq

```ruby
class User < ApplicationRecord
  mount_uploader :avatar, AvatarUploader
  process_in_background :avatar
end
```

Requires `carrierwave_backgrounder` gem.

## Testing

### In Tests

Use file storage in test environment:

```ruby
# config/initializers/carrierwave.rb
CarrierWave.configure do |config|
  if Rails.env.test?
    config.storage = :file
    config.enable_processing = false
  else
    config.storage = :imagekit
  end
end
```

### RSpec Setup

```ruby
# spec/rails_helper.rb
RSpec.configure do |config|
  config.after(:each) do
    CarrierWave.clean_cached_files!
  end
end
```

### Factory Bot

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    avatar { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/avatar.jpg'), 'image/jpeg') }
  end
end
```

## Migration from File Storage

To migrate existing CarrierWave files to ImageKit:

```ruby
# Create a migration task
# lib/tasks/migrate_to_imagekit.rake
namespace :carrierwave do
  desc "Migrate CarrierWave files to ImageKit"
  task migrate_to_imagekit: :environment do
    User.find_each do |user|
      if user.avatar.present?
        # Create a temporary file from existing upload
        file = File.open(user.avatar.path)
        
        # Change storage
        user.class.mount_uploader :avatar, AvatarUploader
        AvatarUploader.storage = :imagekit
        
        # Re-upload to ImageKit
        user.avatar = file
        user.save!
        
        file.close
      end
    end
  end
end
```

Run with: `rails carrierwave:migrate_to_imagekit`

## Troubleshooting

### Files Not Uploading

1. Verify ImageKit credentials in configuration
2. Check `public_key` and `private_key` are set correctly
3. Ensure the uploader has `storage :imagekit`

### URLs Not Generating

1. Verify `url_endpoint` is configured
2. Check that file was uploaded: `@user.avatar.file.exists?`
3. Test with basic URL first: `@user.avatar.url`

### Performance Issues

- Avoid processing versions - use ImageKit on-the-fly transformations instead
- Use background jobs for large uploads
- Enable CDN caching in ImageKit dashboard

## Comparison: CarrierWave vs Active Storage

### Use CarrierWave if:
- You're migrating an existing CarrierWave app
- You prefer explicit uploader classes
- You need fine-grained control over file processing

### Use Active Storage if:
- You're starting a new Rails 6+ app
- You want Rails' native solution
- You prefer convention over configuration
- You need multiple storage services (development/production)

Both work great with `imagekit-rails`! 🎉
