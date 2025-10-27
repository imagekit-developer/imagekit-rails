# frozen_string_literal: true

require 'imagekit/rails/active_storage/service'

# Active Storage service adapter for ImageKit
module ActiveStorage
  class Service
    class ImageKitService < Imagekit::Rails::ActiveStorage::Service
    end
  end
end
