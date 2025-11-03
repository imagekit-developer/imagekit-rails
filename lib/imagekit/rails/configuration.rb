# frozen_string_literal: true

module Imagekit
  module Rails
    # Configuration class for ImageKit Rails integration
    #
    # This class stores all the configuration settings needed for ImageKit to work.
    # By default, it reads from environment variables, but can be customized via the configure block.
    #
    # @example Basic configuration
    #   Imagekit::Rails.configure do |config|
    #     config.private_key = 'your_private_key'
    #     config.public_key = 'your_public_key'
    #     config.url_endpoint = 'https://ik.imagekit.io/your_imagekit_id'
    #   end
    #
    # @example Using environment variables (default)
    #   # .env file
    #   IMAGEKIT_PRIVATE_KEY=private_xxx
    #   IMAGEKIT_PUBLIC_KEY=public_xxx
    #   IMAGEKIT_URL_ENDPOINT=https://ik.imagekit.io/your_imagekit_id
    #
    # @see https://github.com/imagekit-developer/imagekit-ruby ImageKit Ruby SDK
    class Configuration
      # @!attribute [rw] private_key
      #   @return [String, nil] ImageKit private key for authentication (default: ENV['IMAGEKIT_PRIVATE_KEY'])
      # @!attribute [rw] public_key
      #   @return [String, nil] ImageKit public key for client-side operations (default: ENV['IMAGEKIT_PUBLIC_KEY'])
      # @!attribute [rw] url_endpoint
      #   @return [String, nil] ImageKit URL endpoint (default: ENV['IMAGEKIT_URL_ENDPOINT'])
      # @!attribute [rw] transformation_position
      #   @return [Symbol] Position of transformation params in URL (:query or :path, default: :query)
      # @!attribute [rw] responsive
      #   @return [Boolean] Enable responsive image generation (default: true)
      # @!attribute [rw] device_breakpoints
      #   @return [Array<Integer>] Breakpoints for device-based responsive images (default: [640, 750, 828, 1080, 1200, 1920, 2048, 3840])
      # @!attribute [rw] image_breakpoints
      #   @return [Array<Integer>] Breakpoints for content-based responsive images (default: [16, 32, 48, 64, 96, 128, 256, 384])
      attr_accessor :private_key, :public_key, :url_endpoint, :transformation_position,
                    :responsive, :device_breakpoints, :image_breakpoints

      def initialize
        @private_key = ENV['IMAGEKIT_PRIVATE_KEY']
        @public_key = ENV['IMAGEKIT_PUBLIC_KEY']
        @url_endpoint = ENV['IMAGEKIT_URL_ENDPOINT']
        @transformation_position = :query
        @responsive = true
        @device_breakpoints = [640, 750, 828, 1080, 1200, 1920, 2048, 3840]
        @image_breakpoints = [16, 32, 48, 64, 96, 128, 256, 384]
      end

      # Returns the ImageKit client instance
      #
      # The client is initialized lazily and cached for reuse.
      # It uses the configured private_key.
      #
      # @return [Imagekitio::Client] The ImageKit SDK client
      # @see https://www.gemdocs.org/gems/imagekitio/4.0.0/Imagekitio/Client.html ImageKit Client docs
      def client
        @client ||= Imagekitio::Client.new(
          private_key: private_key
        )
      end
    end

    class << self
      attr_writer :configuration

      # Returns the current configuration instance
      #
      # @return [Configuration] The current configuration
      def configuration
        @configuration ||= Configuration.new
      end

      # Configure ImageKit Rails settings
      #
      # @example
      #   Imagekit::Rails.configure do |config|
      #     config.private_key = 'your_private_key'
      #     config.public_key = 'your_public_key'
      #     config.url_endpoint = 'https://ik.imagekit.io/your_imagekit_id'
      #     config.transformation_position = :path
      #     config.responsive = false
      #   end
      #
      # @yield [Configuration] The configuration instance to modify
      # @return [void]
      def configure
        yield(configuration)
      end

      # Reset configuration to default values
      #
      # This creates a new Configuration instance with default values from environment variables.
      #
      # @return [Configuration] The new configuration instance
      def reset_configuration!
        @configuration = Configuration.new
      end
    end
  end
end
