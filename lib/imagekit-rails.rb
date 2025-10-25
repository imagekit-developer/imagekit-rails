# frozen_string_literal: true

require 'imagekit'
require_relative 'imagekit/rails/version'
require_relative 'imagekit/rails/configuration'
require_relative 'imagekit/rails/helper'
require_relative 'imagekit/rails/railtie' if defined?(Rails::Railtie)

module Imagekit
  module Rails
    class Error < StandardError; end
  end
end
