# frozen_string_literal: true

module Imagekit
  module Rails
    module ActiveStorage
      # Extensions for ActiveStorage::Attached to support ImageKit transformations
      module AttachedExtensions
        # Generate ImageKit URL for an Active Storage attachment
        #
        # @param transformation [Array<Hash>] ImageKit transformations
        # @param signed [Boolean] Whether to sign the URL
        # @param expires_in [Integer] Expiration time in seconds for signed URLs
        # @return [String] ImageKit URL
        def imagekit_url(transformation: nil, signed: false, expires_in: nil)
          return nil unless attached?

          config = Imagekit::Rails.configuration
          helper = config.client.helper

          # Get the key (path) for the attachment
          key = blob.key

          src_options = Imagekit::Models::SrcOptions.new(
            src: key,
            url_endpoint: config.url_endpoint,
            transformation: transformation || [],
            signed: signed,
            expires_in: expires_in
          )

          helper.build_url(src_options)
        end

        # Generate ImageKit responsive image attributes for an Active Storage attachment
        #
        # @param width [Integer] Target width
        # @param sizes [String] Sizes attribute
        # @param transformation [Array<Hash>] ImageKit transformations
        # @param device_breakpoints [Array<Integer>] Device width breakpoints
        # @param image_breakpoints [Array<Integer>] Image width breakpoints
        # @return [Hash] Hash with :src, :srcset, and :sizes keys
        def imagekit_responsive_attributes(width: nil, sizes: nil, transformation: nil, device_breakpoints: nil, image_breakpoints: nil,
                                           signed: false, expires_in: nil)
          return {} unless attached?

          config = Imagekit::Rails.configuration
          helper = config.client.helper

          # Get the key (path) for the attachment
          key = blob.key

          responsive_options = Imagekit::Models::GetImageAttributesOptions.new(
            src: key,
            url_endpoint: config.url_endpoint,
            width: width,
            sizes: sizes,
            transformation: transformation || [],
            device_breakpoints: device_breakpoints || config.device_breakpoints,
            image_breakpoints: image_breakpoints || config.image_breakpoints,
            signed: signed,
            expires_in: expires_in
          )

          attrs = helper.get_responsive_image_attributes(responsive_options)

          {
            src: attrs.src,
            srcset: attrs.src_set,
            sizes: attrs.sizes
          }.compact
        end
      end
    end
  end
end

# Extend ActiveStorage::Attached classes if ActiveStorage is available
if defined?(ActiveStorage)
  ActiveStorage::Attached::One.include(Imagekit::Rails::ActiveStorage::AttachedExtensions)
  ActiveStorage::Attached::Many.class_eval do
    # For has_many_attached, apply to each attachment
    def imagekit_urls(**options)
      map { |attachment| attachment.imagekit_url(**options) }
    end
  end
end
