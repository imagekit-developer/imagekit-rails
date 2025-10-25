# ImageKit Rails Gem - Summary

## Overview
A simple Rails gem that provides two view helpers for ImageKit.io integration:
- `ik_image_tag` - For images with transformations and responsive support
- `ik_video_tag` - For videos with transformations

## Project Structure

```
imagekit-rails/
├── lib/
│   ├── imagekit-rails.rb              # Main entry point
│   └── imagekit/
│       └── rails/
│           ├── version.rb             # Gem version
│           ├── configuration.rb        # Configuration module
│           ├── helper.rb              # ik_image_tag & ik_video_tag
│           └── railtie.rb             # Rails integration
├── spec/
│   ├── spec_helper.rb                 # RSpec configuration
│   └── helper_spec.rb                 # Tests for helpers
├── examples/
│   ├── imagekit.rb                    # Example initializer
│   ├── controller_example.rb          # Example controller
│   └── view_examples.html.erb         # Example views
├── imagekit-rails.gemspec             # Gem specification
├── Gemfile                            # Dependencies
├── Rakefile                           # Rake tasks
├── README.md                          # Full documentation
├── QUICKSTART.md                      # Quick start guide
├── CHANGELOG.md                       # Version history
├── CONTRIBUTING.md                    # Contribution guidelines
└── LICENSE                            # MIT License
```

## Key Features

### 1. ik_image_tag
- Automatic responsive images (srcset generation)
- All ImageKit transformations supported
- Lazy loading by default
- Signed URLs support
- Overlays (text, image, video, solid color)
- AI transformations (background removal, upscaling, etc.)

### 2. ik_video_tag
- Video transformations
- Standard video attributes (controls, autoplay, loop, muted)
- Poster image support
- Preload options
- Signed URLs support

## Installation

```ruby
# Gemfile
gem 'imagekit-rails'
```

```ruby
# config/initializers/imagekit.rb
Imagekit::Rails.configure do |config|
  config.url_endpoint = "https://ik.imagekit.io/your_imagekit_id"
  config.public_key = ENV['IMAGEKIT_PUBLIC_KEY']
  config.private_key = ENV['IMAGEKIT_PRIVATE_KEY']
end
```

## Usage Examples

### Images
```erb
<!-- Basic -->
<%= ik_image_tag("/photo.jpg", alt: "Photo") %>

<!-- With transformations -->
<%= ik_image_tag(
  "/photo.jpg",
  transformation: [{ width: 400, height: 300 }],
  alt: "Resized Photo"
) %>

<!-- Responsive -->
<%= ik_image_tag(
  "/photo.jpg",
  width: 800,
  sizes: "(max-width: 600px) 100vw, 800px",
  alt: "Responsive Photo"
) %>
```

### Videos
```erb
<!-- Basic -->
<%= ik_video_tag("/video.mp4", controls: true) %>

<!-- With transformations -->
<%= ik_video_tag(
  "/video.mp4",
  transformation: [{ width: 640, height: 480 }],
  controls: true
) %>

<!-- With poster -->
<%= ik_video_tag(
  "/video.mp4",
  controls: true,
  poster: "https://ik.imagekit.io/your_id/video.mp4/ik-thumbnail.jpg"
) %>
```

## Configuration Options

### Global (Initializer)
- `url_endpoint` - Your ImageKit URL endpoint (required)
- `public_key` - Public API key (optional)
- `private_key` - Private API key (optional, for signed URLs)
- `transformation_position` - :query or :path (default: :query)
- `responsive` - Enable/disable responsive images (default: true)
- `device_breakpoints` - Array of device widths (default: [640, 750, 828, 1080, 1200, 1920, 2048, 3840])
- `image_breakpoints` - Array of image widths (default: [16, 32, 48, 64, 96, 128, 256, 384])

### Per-Tag Options

#### ik_image_tag
- `src` - Image path (required)
- `transformation` - Array of transformation objects
- `alt` - Alt text
- `width`, `height` - Dimensions
- `loading` - "lazy" or "eager"
- `class` - CSS classes
- `data` - Data attributes
- `sizes` - Sizes attribute for responsive images
- `responsive` - Enable/disable responsive (default: from config)
- `signed` - Enable signed URLs
- `expires_in` - Expiration time in seconds
- Plus any standard HTML img attributes

#### ik_video_tag
- `src` - Video path (required)
- `transformation` - Array of transformation objects
- `width`, `height` - Dimensions
- `controls` - Show controls
- `autoplay` - Auto play
- `loop` - Loop video
- `muted` - Mute video
- `poster` - Poster image URL
- `preload` - "none", "metadata", or "auto"
- `class` - CSS classes
- `data` - Data attributes
- `signed` - Enable signed URLs
- `expires_in` - Expiration time in seconds
- Plus any standard HTML video attributes

## Dependencies

- `imagekit` gem (~> 0.0.1) - Core ImageKit Ruby SDK
- `rails` (>= 6.0) - Rails framework

## Testing

```bash
bundle exec rspec
```

## Documentation

- README.md - Complete feature documentation
- QUICKSTART.md - Quick start guide
- examples/ - Working examples
- Inline YARD documentation in code

## License

MIT License - See LICENSE file

## Support

- GitHub: https://github.com/imagekit-developer/imagekit-rails
- ImageKit Docs: https://imagekit.io/docs
- Support: support@imagekit.io
