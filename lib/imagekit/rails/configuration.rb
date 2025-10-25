# frozen_string_literal: true

module Imagekit
  module Rails
    class Configuration
      attr_accessor :private_key, :url_endpoint, :transformation_position,
                    :responsive, :device_breakpoints, :image_breakpoints

      def initialize
        @private_key = ENV['IMAGEKIT_PRIVATE_KEY']
        @url_endpoint = ENV['IMAGEKIT_URL_ENDPOINT']
        @transformation_position = :query
        @responsive = true
        @device_breakpoints = [640, 750, 828, 1080, 1200, 1920, 2048, 3840]
        @image_breakpoints = [16, 32, 48, 64, 96, 128, 256, 384]
      end

      def client
        @client ||= Imagekit::Client.new(
          private_key: private_key,
          base_url: url_endpoint
        )
      end
    end

    class << self
      attr_writer :configuration

      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration)
      end

      def reset_configuration!
        @configuration = Configuration.new
      end
    end
  end
end
