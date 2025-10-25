# Quick Start Guide

This guide will help you get started with ImageKit Rails in just a few minutes.

## Installation

1. Add the gem to your Gemfile:

```ruby
gem 'imagekit-rails'
```

2. Install the gem:

```bash
bundle install
```

## Configuration

Create an initializer at `config/initializers/imagekit.rb`:

```ruby
Imagekit::Rails.configure do |config|
  config.url_endpoint = "https://ik.imagekit.io/your_imagekit_id"
  config.public_key = ENV['IMAGEKIT_PUBLIC_KEY']
  config.private_key = ENV['IMAGEKIT_PRIVATE_KEY']
end
```

Or set environment variables:

```bash
IMAGEKIT_URL_ENDPOINT=https://ik.imagekit.io/your_imagekit_id
IMAGEKIT_PUBLIC_KEY=your_public_key
IMAGEKIT_PRIVATE_KEY=your_private_key
```

## Basic Usage

This gem provides two helpers: `ik_image_tag` and `ik_video_tag`.

### In Your Views

```erb
<!-- Basic image -->
<%= ik_image_tag("/path/to/image.jpg", alt: "My Image") %>

<!-- With transformations -->
<%= ik_image_tag(
  "/photo.jpg",
  transformation: [{ width: 400, height: 300 }],
  alt: "Resized Image"
) %>

<!-- Responsive image -->
<%= ik_image_tag(
  "/photo.jpg",
  width: 800,
  sizes: "(max-width: 600px) 100vw, 800px",
  alt: "Responsive Image"
) %>

<!-- Basic video -->
<%= ik_video_tag("/video.mp4", controls: true) %>

<!-- Video with transformations -->
<%= ik_video_tag(
  "/video.mp4",
  transformation: [{ width: 640, height: 480 }],
  controls: true,
  preload: "metadata"
) %>
```

## Common Use Cases

### Product Images

```erb
<%= ik_image_tag(
  product.image_path,
  transformation: [
    { width: 400, height: 400, crop: "at_max" },
    { quality: 85 }
  ],
  alt: product.name,
  class: "product-image"
) %>
```

### Profile Avatars

```erb
<%= ik_image_tag(
  user.avatar_path,
  transformation: [
    { width: 200, height: 200, crop: "at_max" },
    { radius: "max" }
  ],
  alt: user.name,
  class: "avatar"
) %>
```

### Hero Banners

```erb
<%= ik_image_tag(
  "/hero-background.jpg",
  transformation: [
    { width: 1920, height: 600, crop: "at_max" },
    { quality: 90 }
  ],
  alt: "Hero Banner",
  loading: "eager"
) %>
```

### Videos

```erb
<!-- Video with poster -->
<%= ik_video_tag(
  "/promotional-video.mp4",
  controls: true,
  poster: "https://ik.imagekit.io/your_imagekit_id/promotional-video.mp4/ik-thumbnail.jpg",
  width: 800
) %>
```

## Next Steps

- Check out the [README](README.md) for complete documentation
- Explore [examples](examples/) for more advanced use cases
- Learn about [transformations](https://imagekit.io/docs/transformations)
- Understand [responsive images](https://imagekit.io/docs/responsive-images)

## Getting Your ImageKit Credentials

1. Sign up for free at [ImageKit.io](https://imagekit.io)
2. Find your URL endpoint in the [dashboard](https://imagekit.io/dashboard/url-endpoints)
3. Get your API keys from [developer settings](https://imagekit.io/dashboard/developer/api-keys)

## Need Help?

- [Documentation](https://imagekit.io/docs)
- [Support](https://imagekit.io/support)
- [Email](mailto:support@imagekit.io)
