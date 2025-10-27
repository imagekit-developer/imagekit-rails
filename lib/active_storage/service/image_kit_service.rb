# frozen_string_literal: true

# Active Storage service loader for ImageKit
# This file allows Active Storage to autoload the ImageKit service
# when configured with `service: ImageKit` in storage.yml

require 'imagekit/rails/active_storage/service'

module ActiveStorage
  module Service
    # Alias for ImageKit service to match Active Storage naming conventions
    ImageKitService = Imagekit::Rails::ActiveStorage::Service
  end
end
