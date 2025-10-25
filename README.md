# ImageKit Rails

Rails view helpers for [ImageKit.io](https://imagekit.io) - simple `ik_image_tag` and `ik_video_tag` helpers similar to the ImageKit React SDK.

[![Gem Version](https://badge.fury.io/rb/imagekit-rails.svg)](https://badge.fury.io/rb/imagekit-rails)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- 🎨 **Easy Transformations** - Resize, crop, rotate, and apply effects with simple parameters
- 📱 **Responsive Images** - Automatic `srcset` generation for optimal image delivery
- ⚡ **Lazy Loading** - Built-in lazy loading support
- 🎭 **Overlays** - Add text, image, video, or solid color overlays
- 🤖 **AI Transformations** - Background removal, upscaling, and more
- 🔐 **Signed URLs** - Secure your images with signed URLs
- � **Video Support** - Full video tag support with transformations

## Installation

Add these lines to your application's Gemfile:

```ruby
# ImageKit core gem (currently on GitHub, not yet published to RubyGems)
gem 'imagekit', git: 'https://github.com/stainless-sdks/imagekit-ruby.git'

# ImageKit Rails helpers
gem 'imagekit-rails'
```

And then execute:

```bash
bundle install
```

**Note:** The `imagekit` gem is currently hosted on GitHub. Once it's published to RubyGems, you can remove the git reference.

## Configuration

Create an initializer at `config/initializers/imagekit.rb`:

```ruby
Imagekit::Rails.configure do |config|
  config.url_endpoint = "https://ik.imagekit.io/your_imagekit_id"
  config.public_key = ENV['IMAGEKIT_PUBLIC_KEY']
  config.private_key = ENV['IMAGEKIT_PRIVATE_KEY']
  
  # Optional: Configure default settings
  config.transformation_position = :query  # or :path
  config.responsive = true
  config.device_breakpoints = [640, 750, 828, 1080, 1200, 1920, 2048, 3840]
  config.image_breakpoints = [16, 32, 48, 64, 96, 128, 256, 384]
end
```

You can also set these values via environment variables:
- `IMAGEKIT_URL_ENDPOINT`
- `IMAGEKIT_PUBLIC_KEY`
- `IMAGEKIT_PRIVATE_KEY`

## Usage

This gem provides two view helpers: `ik_image_tag` and `ik_video_tag`.

### Image Tag (`ik_image_tag`)

The simplest way to use ImageKit images:

```erb
<%= ik_image_tag("/path/to/image.jpg", alt: "My Image") %>
```

This generates:

```html
<img src="https://ik.imagekit.io/your_imagekit_id/path/to/image.jpg" alt="My Image" loading="lazy">
```

### Video Tag (`ik_video_tag`)

For videos, use the `ik_video_tag` helper:

```erb
<%= ik_video_tag("/path/to/video.mp4", controls: true) %>
```

This generates:

```html
<video controls>
  <source src="https://ik.imagekit.io/your_imagekit_id/path/to/video.mp4" type="video/mp4">
</video>
```

### Image Transformations

Apply transformations using the `transformation` option:

```erb
<%= ik_image_tag(
  "/photo.jpg",
  transformation: [
    { width: 400, height: 300 }
  ],
  alt: "Resized Image"
) %>
```

### Multiple Transformations (Chained)

You can chain multiple transformations:

```erb
<%= ik_image_tag(
  "/photo.jpg",
  transformation: [
    { width: 400, height: 300 },
    { rotation: 90 },
    { blur: 10 }
  ],
  alt: "Transformed Image"
) %>
```

### Responsive Images

Responsive images are enabled by default and automatically generate `srcset` attributes:

```erb
<%= ik_image_tag(
  "/photo.jpg",
  width: 800,
  sizes: "(max-width: 600px) 100vw, 800px",
  alt: "Responsive Image"
) %>
```

This generates:

```html
<img 
  src="https://ik.imagekit.io/your_imagekit_id/photo.jpg?tr=w-800,c-at_max" 
  srcset="https://ik.imagekit.io/your_imagekit_id/photo.jpg?tr=w-640,c-at_max 640w,
          https://ik.imagekit.io/your_imagekit_id/photo.jpg?tr=w-750,c-at_max 750w,
          ..."
  sizes="(max-width: 600px) 100vw, 800px"
  alt="Responsive Image"
  loading="lazy"
  width="800">
```

To disable responsive images:

```erb
<%= ik_image_tag("/photo.jpg", responsive: false, alt: "Static Image") %>
```

### Lazy Loading

Lazy loading is enabled by default. You can control it with the `loading` attribute:

```erb
<!-- Lazy load (default) -->
<%= ik_image_tag("/photo.jpg", alt: "Lazy Loaded", loading: "lazy") %>

<!-- Eager load -->
<%= ik_image_tag("/photo.jpg", alt: "Eager Loaded", loading: "eager") %>
```

### CSS Classes and Data Attributes

Add CSS classes and data attributes like any Rails image tag:

```erb
<%= ik_image_tag(
  "/photo.jpg",
  alt: "Styled Image",
  class: "img-fluid rounded shadow",
  data: { action: "click->gallery#open", id: 123 }
) %>
```

## Advanced Features

### Text Overlays

Add text overlays to your images:

```erb
<%= ik_image_tag(
  "/background.jpg",
  transformation: [{
    overlay: {
      type: "text",
      text: "Hello World!",
      transformation: [
        { fontSize: 50, fontColor: "FFFFFF" }
      ]
    }
  }],
  alt: "Image with text overlay"
) %>
```

### Image Overlays

Add image overlays:

```erb
<%= ik_image_tag(
  "/background.jpg",
  transformation: [{
    overlay: {
      type: "image",
      input: "logo.png",
      transformation: [
        { width: 100, height: 100 }
      ],
      position: { x: 10, y: 10 }
    }
  }],
  alt: "Image with logo overlay"
) %>
```

### Solid Color Overlays

Add solid color overlays:

```erb
<%= ik_image_tag(
  "/background.jpg",
  transformation: [{
    overlay: {
      type: "solidColor",
      color: "FF0000",
      transformation: [
        { width: 200, height: 200 }
      ]
    }
  }],
  alt: "Image with color overlay"
) %>
```

### AI-Powered Transformations

#### Background Removal

```erb
<%= ik_image_tag(
  "/photo.jpg",
  transformation: [
    { aiRemoveBackground: true }
  ],
  alt: "Photo with background removed"
) %>
```

#### AI Upscaling

```erb
<%= ik_image_tag(
  "/photo.jpg",
  transformation: [
    { aiUpscale: true }
  ],
  alt: "Upscaled photo"
) %>
```

#### AI Drop Shadow

```erb
<%= ik_image_tag(
  "/photo.jpg",
  transformation: [
    { aiDropShadow: true }
  ],
  alt: "Photo with AI drop shadow"
) %>
```

### Video Transformations

Apply transformations to videos:

```erb
<%= ik_video_tag(
  "/video.mp4",
  transformation: [
    { width: 640, height: 480 }
  ],
  controls: true,
  preload: "metadata"
) %>
```

### Video with Poster Image

Add a poster/thumbnail to your video:

```erb
<%= ik_video_tag(
  "/video.mp4",
  controls: true,
  poster: "https://ik.imagekit.io/your_imagekit_id/video.mp4/ik-thumbnail.jpg"
) %>
```

### Signed URLs

For secure delivery, use signed URLs:

```erb
<%= ik_image_tag(
  "/private-photo.jpg",
  signed: true,
  expires_in: 3600,  # Expires in 1 hour
  alt: "Secure Image"
) %>

<%= ik_video_tag(
  "/private-video.mp4",
  signed: true,
  expires_in: 3600,
  controls: true
) %>
```

## Supported Transformations

All ImageKit transformations are supported. Here are some common ones:

| Parameter | Description | Example |
|-----------|-------------|---------|
| `width` | Resize width | `{ width: 400 }` |
| `height` | Resize height | `{ height: 300 }` |
| `aspectRatio` | Aspect ratio | `{ aspectRatio: "16-9" }` |
| `quality` | Image quality | `{ quality: 80 }` |
| `crop` | Crop mode | `{ crop: "at_max" }` |
| `cropMode` | Advanced crop | `{ cropMode: "extract" }` |
| `focus` | Focus area | `{ focus: "face" }` |
| `format` | Output format | `{ format: "webp" }` |
| `radius` | Border radius | `{ radius: 20 }` |
| `background` | Background color | `{ background: "FFFFFF" }` |
| `border` | Border | `{ border: "5_FF0000" }` |
| `rotation` | Rotate image | `{ rotation: 90 }` |
| `blur` | Blur effect | `{ blur: 10 }` |
| `grayscale` | Grayscale | `{ grayscale: true }` |
| `sharpen` | Sharpen | `{ sharpen: 5 }` |
| `overlay` | Add overlay | `{ overlay: {...} }` |

For a complete list of transformations, see the [ImageKit Transformation Documentation](https://imagekit.io/docs/transformations).

## Examples

### Product Image with Hover Effect

```erb
<div class="product-card">
  <%= ik_image_tag(
    "/products/#{product.id}/main.jpg",
    transformation: [
      { width: 400, height: 400, crop: "at_max" },
      { quality: 80 }
    ],
    alt: product.name,
    class: "product-image",
    data: { product_id: product.id }
  ) %>
</div>
```

### Hero Banner with Text Overlay

```erb
<%= ik_image_tag(
  "/hero-background.jpg",
  transformation: [
    { width: 1920, height: 600, crop: "at_max" },
    { quality: 90 },
    {
      overlay: {
        type: "text",
        text: "Welcome to Our Site",
        transformation: [
          { fontSize: 80, fontColor: "FFFFFF", fontFamily: "Arial" }
        ],
        position: { focus: "center" }
      }
    }
  ],
  alt: "Hero Banner",
  class: "hero-image"
) %>
```

### Profile Avatar with Border

```erb
<%= ik_image_tag(
  user.avatar_path,
  transformation: [
    { width: 200, height: 200, crop: "at_max" },
    { radius: "max" },
    { border: "3_0000FF" }
  ],
  alt: user.name,
  class: "avatar"
) %>
```

### Gallery with Responsive Images

```erb
<div class="gallery">
  <% @photos.each do |photo| %>
    <%= ik_image_tag(
      photo.path,
      width: 800,
      sizes: "(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw",
      transformation: [
        { quality: 85 }
      ],
      alt: photo.title,
      class: "gallery-image",
      loading: "lazy"
    ) %>
  <% end %>
</div>
```

## Configuration Options

### Global Configuration

Set default values in your initializer:

```ruby
Imagekit::Rails.configure do |config|
  # Required
  config.url_endpoint = "https://ik.imagekit.io/your_imagekit_id"
  
  # Optional for server-side operations
  config.private_key = ENV['IMAGEKIT_PRIVATE_KEY']
  config.public_key = ENV['IMAGEKIT_PUBLIC_KEY']
  
  # Default transformation position (:query or :path)
  config.transformation_position = :query
  
  # Enable/disable responsive images by default
  config.responsive = true
  
  # Custom breakpoints for responsive images
  config.device_breakpoints = [640, 750, 828, 1080, 1200, 1920, 2048, 3840]
  config.image_breakpoints = [16, 32, 48, 64, 96, 128, 256, 384]
end
```

### Per-Image Override

Override global settings for individual images:

```erb
<%= ik_image_tag(
  "/photo.jpg",
  url_endpoint: "https://ik.imagekit.io/another_account",
  transformation_position: :path,
  responsive: false,
  alt: "Custom configured image"
) %>
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/imagekit-developer/imagekit-rails.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Related Projects

- [ImageKit Ruby SDK](https://github.com/stainless-sdks/imagekit-ruby) - Core Ruby SDK for ImageKit
- [ImageKit React SDK](https://github.com/imagekit-developer/imagekit-react) - React components for ImageKit
- [ImageKit Next.js SDK](https://github.com/imagekit-developer/imagekit-nextjs) - Next.js integration for ImageKit

## Support

- [Documentation](https://imagekit.io/docs)
- [Support](https://imagekit.io/support)
- [Email](mailto:support@imagekit.io)
