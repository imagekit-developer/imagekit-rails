# frozen_string_literal: true

require 'imagekit'
require_relative 'imagekit/rails/version'
require_relative 'imagekit/rails/configuration'
require_relative 'imagekit/rails/helper'

# Load Active Storage integration if ActiveStorage is available
if defined?(ActiveStorage)
  require_relative 'imagekit/rails/active_storage'
  require_relative 'imagekit/rails/active_storage/service'
  require_relative 'imagekit/rails/active_storage/blob_deletion_callback'
end

require_relative 'imagekit/rails/railtie' if defined?(Rails::Railtie)

# ImageKit Rails integration
#
# This is the top-level namespace for the ImageKit Ruby SDK. This gem (`imagekit-rails`)
# provides Rails-specific integrations on top of the core SDK.
#
# ImageKit is a complete media management solution that provides:
# - Real-time image and video transformations (resize, crop, rotate, format conversion, etc.)
# - Intelligent optimization and compression
# - Fast content delivery via global CDN
# - Media storage and organization
# - URL-based transformations with caching
#
# @see Imagekit::Rails Rails integration
# @see https://imagekit.io ImageKit.io homepage
# @see https://github.com/imagekit-developer/imagekit-ruby ImageKit Ruby SDK
# @see https://docs.imagekit.io ImageKit documentation
module Imagekit
  # Rails integration for ImageKit
  #
  # Provides seamless integration between Rails and ImageKit, including:
  #
  # **View Helpers:**
  # - `ik_image_tag` - Generate `<img>` tags with ImageKit URLs, transformations, and responsive images
  # - `ik_video_tag` - Generate `<video>` tags with ImageKit URLs and transformations
  #
  # **Active Storage Adapter:**
  # - Store Rails Active Storage attachments directly in ImageKit
  # - Automatic URL generation for stored files
  # - Support for transformations on stored attachments
  #
  # **Configuration:**
  # - Simple configuration via initializer or environment variables
  # - Support for responsive images with customizable breakpoints
  # - Flexible transformation positioning (query params or path-based)
  #
  # @example Configuration
  #   # config/initializers/imagekit.rb
  #   Imagekit::Rails.configure do |config|
  #     config.url_endpoint = ENV['IMAGEKIT_URL_ENDPOINT']
  #     config.public_key = ENV['IMAGEKIT_PUBLIC_KEY']
  #     config.private_key = ENV['IMAGEKIT_PRIVATE_KEY']
  #   end
  #
  # @example Using view helpers
  #   <%= ik_image_tag("/photo.jpg", transformation: [{ width: 400 }]) %>
  #   <%= ik_video_tag("/video.mp4", controls: true) %>
  #
  # @example Active Storage setup
  #   # config/storage.yml
  #   imagekit:
  #     service: ImageKit
  #
  #   # app/models/user.rb
  #   class User < ApplicationRecord
  #     has_one_attached :avatar
  #   end
  #
  #   # View
  #   <%= ik_image_tag(user.avatar, transformation: [{ width: 200, height: 200 }]) %>
  #
  # @see Imagekit::Rails::Helper View helpers documentation
  # @see Imagekit::Rails::Configuration Configuration options
  # @see Imagekit::Rails::ActiveStorage::Service Active Storage service
  module Rails
    # Standard error for ImageKit Rails gem
    class Error < StandardError; end
  end
end
