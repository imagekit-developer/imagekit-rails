# ImageKit Rails

Rails view helpers and Active Storage integration for [ImageKit.io](https://imagekit.io).

[![Gem Version](https://badge.fury.io/rb/imagekitio-rails.svg)](https://badge.fury.io/rb/imagekitio-rails)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

## Features

- View helpers: `ik_image_tag` and `ik_video_tag` with transformation support
- Active Storage service for storing files in ImageKit
- Automatic responsive images with `srcset` generation
- Image transformations (resize, crop, effects, overlays)
- Video support with transformations
- Signed URLs for secure delivery

## Installation

Add to your `Gemfile`:

```ruby
gem 'imagekitio', git: 'https://github.com/imagekit-developer/imagekit-ruby.git', branch: 'next'
gem 'imagekitio-rails'
```

```bash
bundle install
```

**Note:** The `imagekitio` gem is required but not yet published to RubyGems.

## Configuration

Create `config/initializers/imagekit.rb`:

```ruby
Imagekit::Rails.configure do |config|
  config.url_endpoint = ENV['IMAGEKIT_URL_ENDPOINT']
  config.public_key = ENV['IMAGEKIT_PUBLIC_KEY']
  config.private_key = ENV['IMAGEKIT_PRIVATE_KEY']
  
  # Optional defaults
  # config.transformation_position = :query  # or :path
  # config.responsive = true                 # Enable responsive images
end
```

Get your credentials from [ImageKit Dashboard → API Keys](https://imagekit.io/dashboard/developer/api-keys).

## Quick Start

### View Helpers

Use `ik_image_tag` and `ik_video_tag` in your views:

```erb
<!-- Basic image -->
<%= ik_image_tag("/photo.jpg", alt: "My Photo") %>

<!-- With transformations -->
<%= ik_image_tag("/photo.jpg", transformation: [{ width: 400, height: 300 }], alt: "Resized") %>

<!-- Video -->
<%= ik_video_tag("/video.mp4", controls: true) %>
```

### Active Storage

Store uploaded files in ImageKit:

```yaml
# config/storage.yml
imagekit:
  service: ImageKit
```

```ruby
# config/environments/production.rb
config.active_storage.service = :imagekit
```

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_one_attached :avatar
end
```

```erb
<!-- Display with transformations -->
<%= ik_image_tag(@user.avatar, transformation: [{ width: 200, height: 200 }]) %>
```

**[Full Active Storage Documentation →](ACTIVE_STORAGE.md)**

## Transformations

### Basic Transformations

```erb
<%= ik_image_tag("/photo.jpg", transformation: [{ width: 400, height: 300 }]) %>
```

### Chaining Transformations

```erb
<%= ik_image_tag(
  "/photo.jpg",
  transformation: [
    { width: 400, height: 300 },
    { rotation: 90 },
    { blur: 10 }
  ]
) %>
```

### Responsive Images

Enabled by default. Automatically generates `srcset`:

```erb
<%= ik_image_tag("/photo.jpg", width: 800, sizes: "(max-width: 600px) 100vw, 800px") %>
```

Disable per image:

```erb
<%= ik_image_tag("/photo.jpg", responsive: false) %>
```

### Common Parameters

```erb
<!-- Resize and crop -->
<%= ik_image_tag("/photo.jpg", transformation: [{ width: 400, height: 300, crop: "at_max" }]) %>

<!-- Format and quality -->
<%= ik_image_tag("/photo.jpg", transformation: [{ format: "webp", quality: 80 }]) %>

<!-- Effects -->
<%= ik_image_tag("/photo.jpg", transformation: [{ grayscale: true, blur: 5 }]) %>

<!-- Border and radius -->
<%= ik_image_tag("/photo.jpg", transformation: [{ radius: 20, border: "3_FF0000" }]) %>
```

See [ImageKit Transformation Documentation](https://docs.imagekit.io/features/image-transformations) for all options.

## Advanced Features

### Overlays

Text overlay:

```erb
<%= ik_image_tag(
  "/background.jpg",
  transformation: [{
    overlay: {
      type: "text",
      text: "Hello World",
      transformation: [{ fontSize: 50, fontColor: "FFFFFF" }]
    }
  }]
) %>
```

Image overlay:

```erb
<%= ik_image_tag(
  "/background.jpg",
  transformation: [{
    overlay: {
      type: "image",
      input: "logo.png",
      transformation: [{ width: 100, height: 100 }],
      position: { x: 10, y: 10 }
    }
  }]
) %>
```

### AI Transformations

```erb
<!-- Background removal -->
<%= ik_image_tag("/photo.jpg", transformation: [{ aiRemoveBackground: true }]) %>

<!-- Upscaling -->
<%= ik_image_tag("/photo.jpg", transformation: [{ aiUpscale: true }]) %>

<!-- Drop shadow -->
<%= ik_image_tag("/photo.jpg", transformation: [{ aiDropShadow: true }]) %>
```

### Signed URLs

For secure delivery:

```erb
<%= ik_image_tag("/private.jpg", signed: true, expires_in: 3600) %>
<%= ik_video_tag("/private.mp4", signed: true, expires_in: 3600, controls: true) %>
```

### Video Transformations

```erb
<%= ik_video_tag("/video.mp4", transformation: [{ width: 640, height: 480 }], controls: true) %>
```

## API Reference

### `ik_image_tag(src, options = {})`

**Parameters:**
- `src` - Image path or Active Storage attachment
- `transformation` - Array of transformation hashes
- `responsive` - Enable/disable responsive images (default: `true`)
- `loading` - `"lazy"` (default) or `"eager"`
- `signed` - Generate signed URL (default: `false`)
- `expires_in` - Expiration time in seconds for signed URLs
- `width`, `height`, `alt`, `class`, `data` - Standard HTML attributes

### `ik_video_tag(src, options = {})`

**Parameters:**
- `src` - Video path or Active Storage attachment
- `transformation` - Array of transformation hashes
- `controls`, `autoplay`, `loop`, `muted`, `preload`, `poster` - Standard video attributes
- `signed` - Generate signed URL
- `expires_in` - Expiration time in seconds

## Examples

### Product Gallery

```erb
<% @products.each do |product| %>
  <%= ik_image_tag(
    product.image_path,
    transformation: [{ width: 400, height: 400, crop: "at_max" }, { quality: 80 }],
    alt: product.name,
    class: "product-image"
  ) %>
<% end %>
```

### User Avatar

```erb
<%= ik_image_tag(
  @user.avatar,
  transformation: [
    { width: 200, height: 200, crop: "at_max" },
    { radius: "max" }
  ],
  alt: @user.name
) %>
```

### Hero Banner with Text

```erb
<%= ik_image_tag(
  "/hero.jpg",
  transformation: [
    { width: 1920, height: 600, crop: "at_max" },
    {
      overlay: {
        type: "text",
        text: "Welcome",
        transformation: [{ fontSize: 80, fontColor: "FFFFFF" }]
      }
    }
  ]
) %>
```

## Documentation

- **[Active Storage Integration](ACTIVE_STORAGE.md)** - Complete guide for using ImageKit with Active Storage
- **[API Reference](API.md)** - Detailed API documentation
- **[ImageKit Transformations](https://docs.imagekit.io/features/image-transformations)** - All available transformations

## Development

```bash
bundle install
rake spec
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/imagekit-developer/imagekit-rails.

## License

Apache License 2.0. See [LICENSE](LICENSE) for details.
