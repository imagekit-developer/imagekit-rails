# ImageKit Rails

Rails view helpers and Active Storage integration for [ImageKit.io](https://imagekit.io).

[![Gem Version](https://badge.fury.io/rb/imagekitio-rails.svg)](https://badge.fury.io/rb/imagekitio-rails)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

## Overview

The ImageKit Rails gem provides seamless integration with Ruby on Rails applications, including:

- **View helpers** (`ik_image_tag` and `ik_video_tag`) with transformation support
- **Active Storage service** for storing files in ImageKit
- **Automatic responsive images** with `srcset` generation
- **Image and video transformations** (resize, crop, effects, overlays)
- **Signed URLs** for secure delivery

## Installation

Add to your `Gemfile`:

```ruby
gem 'imagekitio-rails'
```

Run:

```bash
bundle install
```

This will automatically install the required `imagekitio` core SDK (version 4.x) as a dependency.

## Quick Start

Create `config/initializers/imagekit.rb`:

```ruby
Imagekit::Rails.configure do |config|
  config.url_endpoint = ENV['IMAGEKIT_URL_ENDPOINT']
  config.public_key = ENV['IMAGEKIT_PUBLIC_KEY']
  config.private_key = ENV['IMAGEKIT_PRIVATE_KEY']
end
```

Get your credentials from [ImageKit Dashboard → API Keys](https://imagekit.io/dashboard/developer/api-keys).

### Basic Usage

```erb
<!-- Display an image with transformations -->
<%= ik_image_tag("/photo.jpg", transformation: [{ width: 400, height: 300 }], alt: "My Photo") %>

<!-- Display a video -->
<%= ik_video_tag("/video.mp4", controls: true) %>

<!-- Active Storage attachment with transformations -->
<%= ik_image_tag(@user.avatar, transformation: [{ width: 200, height: 200 }]) %>
```

## Documentation

- **[Rails Integration Guide](https://imagekit.io/docs/integration/ruby/ruby-on-rails)** - Complete integration guide
- **[Ruby SDK](https://imagekit.io/docs/integration/ruby)** - Core SDK for non-Rails applications
- **[Transformation Reference](https://imagekit.io/docs/transformations)** - All available transformation options
- **[API Reference](https://imagekit.io/docs/api-reference)** - Complete REST API documentation
- **[RubyDoc](https://gemdocs.org/gems/imagekitio-rails)** - Gem API documentation

## Support

- **GitHub Issues**: [Report bugs or request features](https://github.com/imagekit-developer/imagekit-rails/issues)
- **ImageKit Support**: [Contact support](https://imagekit.io/contact)
- **Documentation**: [imagekit.io/docs](https://imagekit.io/docs)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/imagekit-developer/imagekit-rails.

## License

Apache License 2.0. See [LICENSE](LICENSE) for details.
