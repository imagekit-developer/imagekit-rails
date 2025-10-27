# frozen_string_literal: true

require 'imagekit'
require_relative 'imagekit/rails/version'
require_relative 'imagekit/rails/configuration'
require_relative 'imagekit/rails/helper'
require_relative 'imagekit/rails/railtie' if defined?(Rails::Railtie)

# Load Active Storage integration if ActiveStorage is available
if defined?(ActiveStorage)
  require_relative 'imagekit/rails/active_storage/service'
  require_relative 'imagekit/rails/active_storage/attached_extensions'
end

# Load CarrierWave integration if CarrierWave is available
require_relative 'imagekit/rails/carrierwave/storage' if defined?(CarrierWave)

module Imagekit
  module Rails
    class Error < StandardError; end
  end
end
