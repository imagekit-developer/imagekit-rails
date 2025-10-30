# frozen_string_literal: true

require 'imagekit/rails/active_storage/service'

# Active Storage naming convention alias. Do not use directly.
# Use `service: ImageKit` in storage.yml instead.
#
# @private
# @see Imagekit::Rails::ActiveStorage::Service
module ActiveStorage
  class Service
    class ImageKitService < Imagekit::Rails::ActiveStorage::Service
    end
  end
end
