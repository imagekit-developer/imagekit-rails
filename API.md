# ImageKit Rails API Reference

This document provides the complete API reference for the two helpers provided by this gem.

## ik_image_tag

Generate an HTML image tag with ImageKit transformations and responsive image support.

### Signature

```ruby
ik_image_tag(src, **options) → String
```

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `src` | String | Yes | The image path (relative or absolute) |
| `**options` | Hash | No | Additional options (see below) |

### Options

#### ImageKit Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `url_endpoint` | String | from config | ImageKit URL endpoint |
| `transformation` | Array<Hash> | `[]` | Array of transformation objects |
| `query_parameters` | Hash | `nil` | Additional query parameters |
| `transformation_position` | Symbol | `:query` | `:path` or `:query` |
| `responsive` | Boolean | `true` | Enable responsive images (srcset) |
| `device_breakpoints` | Array<Integer> | from config | Device width breakpoints |
| `image_breakpoints` | Array<Integer> | from config | Image width breakpoints |
| `signed` | Boolean | `false` | Enable signed URLs |
| `expires_in` | Integer | `nil` | Expiration time in seconds |

#### HTML Attributes

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `alt` | String | `""` | Alt text |
| `width` | Integer/String | `nil` | Width attribute |
| `height` | Integer/String | `nil` | Height attribute |
| `loading` | String | `"lazy"` | `"lazy"` or `"eager"` |
| `sizes` | String | `nil` | Sizes attribute for responsive images |
| `class` | String | `nil` | CSS classes |
| `data` | Hash | `nil` | Data attributes |

Any additional options are passed through as HTML attributes.

### Examples

```erb
<!-- Basic -->
<%= ik_image_tag("/photo.jpg", alt: "My Photo") %>

<!-- With transformations -->
<%= ik_image_tag(
  "/photo.jpg",
  transformation: [
    { width: 400, height: 300, crop: "at_max" },
    { quality: 85 }
  ],
  alt: "Resized Photo"
) %>

<!-- Responsive -->
<%= ik_image_tag(
  "/photo.jpg",
  width: 800,
  sizes: "(max-width: 768px) 100vw, 800px",
  alt: "Responsive Photo"
) %>

<!-- With overlay -->
<%= ik_image_tag(
  "/background.jpg",
  transformation: [{
    overlay: {
      type: "text",
      text: "Hello World",
      transformation: [{ fontSize: 50, fontColor: "FFFFFF" }]
    }
  }],
  alt: "Image with overlay"
) %>

<!-- AI background removal -->
<%= ik_image_tag(
  "/person.jpg",
  transformation: [{ aiRemoveBackground: true }],
  alt: "Person with background removed"
) %>

<!-- Signed URL -->
<%= ik_image_tag(
  "/private/photo.jpg",
  signed: true,
  expires_in: 3600,
  alt: "Secure Photo"
) %>

<!-- Non-responsive -->
<%= ik_image_tag(
  "/photo.jpg",
  responsive: false,
  transformation: [{ width: 500 }],
  alt: "Static Photo"
) %>

<!-- With CSS and data attributes -->
<%= ik_image_tag(
  "/photo.jpg",
  alt: "Styled Photo",
  class: "img-fluid rounded shadow",
  data: { action: "click->gallery#open", id: 123 }
) %>
```

---

## ik_video_tag

Generate an HTML video tag with ImageKit transformations.

### Signature

```ruby
ik_video_tag(src, **options) → String
```

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `src` | String | Yes | The video path (relative or absolute) |
| `**options` | Hash | No | Additional options (see below) |

### Options

#### ImageKit Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `url_endpoint` | String | from config | ImageKit URL endpoint |
| `transformation` | Array<Hash> | `[]` | Array of transformation objects |
| `query_parameters` | Hash | `nil` | Additional query parameters |
| `transformation_position` | Symbol | `:query` | `:path` or `:query` |
| `signed` | Boolean | `false` | Enable signed URLs |
| `expires_in` | Integer | `nil` | Expiration time in seconds |

#### HTML Attributes

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `width` | Integer/String | `nil` | Width attribute |
| `height` | Integer/String | `nil` | Height attribute |
| `poster` | String | `nil` | Poster image URL |
| `preload` | String | `nil` | `"none"`, `"metadata"`, or `"auto"` |
| `controls` | Boolean | `false` | Show video controls |
| `autoplay` | Boolean | `false` | Auto play video |
| `loop` | Boolean | `false` | Loop video |
| `muted` | Boolean | `false` | Mute video |
| `class` | String | `nil` | CSS classes |
| `data` | Hash | `nil` | Data attributes |

Any additional options are passed through as HTML attributes.

### Examples

```erb
<!-- Basic -->
<%= ik_video_tag("/video.mp4", controls: true) %>

<!-- With transformations -->
<%= ik_video_tag(
  "/video.mp4",
  transformation: [
    { width: 640, height: 480 }
  ],
  controls: true
) %>

<!-- With poster -->
<%= ik_video_tag(
  "/video.mp4",
  controls: true,
  poster: "https://ik.imagekit.io/your_id/video.mp4/ik-thumbnail.jpg"
) %>

<!-- Lazy loading with preload -->
<%= ik_video_tag(
  "/video.mp4",
  controls: true,
  preload: "none",
  poster: "https://ik.imagekit.io/your_id/video.mp4/ik-thumbnail.jpg"
) %>

<!-- Autoplay muted loop -->
<%= ik_video_tag(
  "/background-video.mp4",
  autoplay: true,
  loop: true,
  muted: true,
  class: "hero-video"
) %>

<!-- Signed URL -->
<%= ik_video_tag(
  "/private/video.mp4",
  signed: true,
  expires_in: 3600,
  controls: true
) %>

<!-- With video overlay -->
<%= ik_video_tag(
  "/main-video.mp4",
  transformation: [{
    overlay: {
      type: "video",
      input: "overlay-video.mp4",
      timing: { start: 5, duration: 10 }
    }
  }],
  controls: true
) %>

<!-- With CSS and data attributes -->
<%= ik_video_tag(
  "/video.mp4",
  controls: true,
  class: "video-player",
  data: { video_id: 123, action: "play->analytics#track" }
) %>
```

---

## Transformation Objects

Both helpers accept an array of transformation objects. Each object can contain any ImageKit transformation parameter.

### Common Transformations

```ruby
# Resize
{ width: 400, height: 300 }

# Crop
{ width: 400, height: 300, crop: "at_max" }

# Quality
{ quality: 85 }

# Format
{ format: "webp" }

# Effects
{ blur: 10 }
{ grayscale: true }
{ sharpen: 5 }

# AI Transformations
{ aiRemoveBackground: true }
{ aiUpscale: true }
{ aiDropShadow: true }

# Overlays
{
  overlay: {
    type: "text",
    text: "Hello",
    transformation: [{ fontSize: 50 }]
  }
}
```

See [ImageKit Transformation Documentation](https://imagekit.io/docs/transformations) for all available transformations.

---

## Configuration

Configure defaults in `config/initializers/imagekit.rb`:

```ruby
Imagekit::Rails.configure do |config|
  # Required
  config.url_endpoint = "https://ik.imagekit.io/your_imagekit_id"
  
  # Optional
  config.private_key = ENV['IMAGEKIT_PRIVATE_KEY']
  config.transformation_position = :query
  config.responsive = true
  config.device_breakpoints = [640, 750, 828, 1080, 1200, 1920, 2048, 3840]
  config.image_breakpoints = [16, 32, 48, 64, 96, 128, 256, 384]
end
```

Or use environment variables:
- `IMAGEKIT_URL_ENDPOINT`
- `IMAGEKIT_PRIVATE_KEY`
