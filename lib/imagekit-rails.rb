# frozen_string_literal: true

require 'imagekit'
require_relative 'imagekit/rails/version'
require_relative 'imagekit/rails/configuration'
require_relative 'imagekit/rails/helper'

# Load Active Storage integration if ActiveStorage is available
if defined?(ActiveStorage)
  require_relative 'imagekit/rails/active_storage'
  require_relative 'imagekit/rails/active_storage/service'
end

require_relative 'imagekit/rails/railtie' if defined?(Rails::Railtie)

module Imagekit
  module Rails
    class Error < StandardError; end
  end
end
