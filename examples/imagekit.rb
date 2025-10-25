# frozen_string_literal: true

# ImageKit Rails Example Configuration
#
# Place this file in config/initializers/imagekit.rb

Imagekit::Rails.configure do |config|
  # Required: Your ImageKit URL endpoint
  # You can find this in your ImageKit dashboard at https://imagekit.io/dashboard/url-endpoints
  config.url_endpoint = ENV.fetch('IMAGEKIT_URL_ENDPOINT', 'https://ik.imagekit.io/your_imagekit_id')

  # Optional: Your ImageKit public key (required for client-side uploads)
  # You can find this in your ImageKit dashboard at https://imagekit.io/dashboard/developer/api-keys
  config.public_key = ENV['IMAGEKIT_PUBLIC_KEY']

  # Optional: Your ImageKit private key (required for server-side operations and signed URLs)
  # IMPORTANT: Never expose your private key in client-side code
  config.private_key = ENV['IMAGEKIT_PRIVATE_KEY']

  # Optional: Default transformation position
  # :query - Transformations appear as query parameters (e.g., ?tr=w-400,h-300)
  # :path  - Transformations appear in the URL path (e.g., /tr:w-400,h-300/)
  # Default: :query
  config.transformation_position = :query

  # Optional: Enable/disable responsive images by default
  # When true, automatically generates srcset attributes for optimal image delivery
  # Default: true
  config.responsive = true

  # Optional: Device width breakpoints for responsive images
  # These represent typical device widths and are used to generate srcset candidates
  # Default: [640, 750, 828, 1080, 1200, 1920, 2048, 3840]
  config.device_breakpoints = [640, 750, 828, 1080, 1200, 1920, 2048, 3840]

  # Optional: Image width breakpoints for responsive images
  # These are smaller breakpoints typically used for thumbnails and smaller images
  # Default: [16, 32, 48, 64, 96, 128, 256, 384]
  config.image_breakpoints = [16, 32, 48, 64, 96, 128, 256, 384]
end
