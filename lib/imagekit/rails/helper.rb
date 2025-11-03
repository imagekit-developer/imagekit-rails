# frozen_string_literal: true

module Imagekit
  module Rails
    # View helpers for generating ImageKit image and video tags
    #
    # This module provides Rails view helpers that generate `<img>` and `<video>` tags
    # with ImageKit URLs, including transformations, responsive images, and signed URLs.
    #
    # These helpers are automatically included in all Rails views and controllers
    # when the gem is loaded (via the Railtie), so you can use them directly without
    # any additional setup.
    #
    # @example Using in views (automatically available)
    #   <%= ik_image_tag("/photo.jpg", width: 400) %>
    #   <%= ik_video_tag("/video.mp4", controls: true) %>
    #
    # @see #ik_image_tag
    # @see #ik_video_tag
    module Helper
      # Generates an image tag with ImageKit URL transformations and responsive image support.
      #
      # @param src [String, ActiveStorage::Attached] Image path or Active Storage attachment
      # @param options [Hash] Image tag options
      #
      # @option options [String] :url_endpoint ImageKit URL endpoint (overrides config)
      # @option options [Array<Hash>] :transformation Array of transformation objects.
      #   See [Transformation docs](https://www.gemdocs.org/gems/imagekitio/4.0.0/Imagekitio/Models/Transformation.html) for all available parameters
      # @option options [Hash{Symbol=>String}] :query_parameters Additional query parameters
      # @option options [Symbol] :transformation_position Position for transformations - `:path` or `:query` (default: `:query`).
      #   See [TransformationPosition](https://www.gemdocs.org/gems/imagekitio/4.0.0/Imagekitio/Models/TransformationPosition.html)
      # @option options [Boolean] :signed Whether to generate a signed URL (default: `false`)
      # @option options [Integer, Float] :expires_in Expiration time in seconds for signed URLs.
      #   If specified, URL will always be signed. See [Signed URLs](https://imagekit.io/docs/media-delivery-basic-security#how-to-generate-signed-urls)
      #
      # @option options [Boolean] :responsive Enable/disable responsive images with `srcset` (default: `true`)
      # @option options [Array<Integer>] :device_breakpoints Device width breakpoints for responsive images
      # @option options [Array<Integer>] :image_breakpoints Image width breakpoints for responsive images
      # @option options [String] :sizes Sizes attribute for responsive images (e.g., `"(max-width: 600px) 100vw, 800px"`)
      #
      # @option options [String] :alt Alt text for the image
      # @option options [Integer, String] :width Width attribute for the img tag
      # @option options [Integer, String] :height Height attribute for the img tag
      # @option options [String] :loading Loading strategy - `"lazy"` (default) or `"eager"`
      # @option options [String] :class CSS classes
      # @option options [Hash] :data Data attributes (e.g., `{ controller: "gallery", action: "click" }`)
      #
      # @return [String] HTML image tag with ImageKit URL
      #
      # @see https://www.gemdocs.org/gems/imagekitio/4.0.0/Imagekitio/Models/SrcOptions.html SrcOptions model
      # @see #ik_video_tag
      #
      # @example Basic usage
      #   ik_image_tag("/path/to/image.jpg", alt: "My Image")
      #
      # @example With Active Storage
      #   ik_image_tag(user.avatar, alt: "User Avatar")
      #
      # @example With transformations
      #   ik_image_tag(
      #     "/path/to/image.jpg",
      #     transformation: [{ width: 400, height: 300 }],
      #     alt: "Resized Image"
      #   )
      #
      # @example With responsive images
      #   ik_image_tag(
      #     "/path/to/image.jpg",
      #     width: 800,
      #     sizes: "(max-width: 600px) 100vw, 800px",
      #     alt: "Responsive Image"
      #   )
      #
      # @example With overlays
      #   ik_image_tag(
      #     "/background.jpg",
      #     transformation: [{
      #       overlay: {
      #         type: "text",
      #         text: "Hello World",
      #         transformation: [{ fontSize: 50, fontColor: "FFFFFF" }]
      #       }
      #     }],
      #     alt: "Image with text overlay"
      #   )
      def ik_image_tag(src, options = {})
        # Handle Active Storage attachments
        if active_storage_attachment?(src)
          return nil unless src.attached?

          src = src.blob.key
        end

        raise ArgumentError, 'src is required' if src.nil? || src.empty?

        config = Imagekit::Rails.configuration
        helper = config.client.helper

        # Extract ImageKit-specific options
        url_endpoint = options.delete(:url_endpoint) || config.url_endpoint
        transformation = options.delete(:transformation) || []
        query_parameters = options.delete(:query_parameters)
        transformation_position = options.delete(:transformation_position) || config.transformation_position
        responsive = options.key?(:responsive) ? options.delete(:responsive) : config.responsive
        signed = options.delete(:signed)
        expires_in = options.delete(:expires_in)

        # Extract HTML attributes
        alt = options.delete(:alt) || ''
        width = options.delete(:width)
        height = options.delete(:height)
        sizes = options.delete(:sizes)
        loading = options.delete(:loading) || 'lazy'
        css_class = options.delete(:class)
        data_attributes = options.delete(:data)
        device_breakpoints = options.delete(:device_breakpoints) || config.device_breakpoints
        image_breakpoints = options.delete(:image_breakpoints) || config.image_breakpoints

        # Build image attributes
        img_attributes = {
          alt: alt,
          loading: loading
        }

        # Add width and height if provided
        img_attributes[:width] = width if width
        img_attributes[:height] = height if height

        # Add CSS class if provided
        img_attributes[:class] = css_class if css_class

        # Add data attributes if provided
        data_attributes&.each do |key, value|
          img_attributes[:"data-#{key}"] = value
        end

        # Add any remaining options as HTML attributes
        img_attributes.merge!(options)

        # Generate responsive image attributes if enabled
        if responsive && url_endpoint
          responsive_options = Imagekitio::Models::GetImageAttributesOptions.new(
            src: src,
            url_endpoint: url_endpoint,
            width: width&.to_i,
            sizes: sizes,
            transformation: transformation,
            transformation_position: transformation_position&.to_sym,
            query_parameters: query_parameters,
            device_breakpoints: device_breakpoints,
            image_breakpoints: image_breakpoints,
            signed: signed,
            expires_in: expires_in
          )

          responsive_attrs = helper.get_responsive_image_attributes(responsive_options)

          # Use the generated attributes
          img_attributes[:src] = responsive_attrs.src
          img_attributes[:srcset] = responsive_attrs.src_set if responsive_attrs.src_set
          # Use hash accessor to avoid type conversion error on nil values
          sizes_value = responsive_attrs[:sizes]
          img_attributes[:sizes] = sizes_value if sizes_value
        else
          # Non-responsive: just build a simple URL
          src_options = Imagekitio::Models::SrcOptions.new(
            src: src,
            url_endpoint: url_endpoint,
            transformation: transformation,
            transformation_position: transformation_position&.to_sym,
            query_parameters: query_parameters,
            signed: signed,
            expires_in: expires_in
          )

          img_attributes[:src] = helper.build_url(src_options)
        end

        # Generate the image tag
        tag(:img, img_attributes)
      end

      # Generates a video tag with ImageKit URL transformations.
      #
      # @param src [String, ActiveStorage::Attached] Video path or Active Storage attachment
      # @param options [Hash] Video tag options
      #
      # @option options [String] :url_endpoint ImageKit URL endpoint (overrides config)
      # @option options [Array<Hash>] :transformation Array of transformation objects.
      #   See [Transformation docs](https://www.gemdocs.org/gems/imagekitio/4.0.0/Imagekitio/Models/Transformation.html) for available parameters
      # @option options [Hash{Symbol=>String}] :query_parameters Additional query parameters
      # @option options [Symbol] :transformation_position Position for transformations - `:path` or `:query` (default: `:query`)
      # @option options [Boolean] :signed Whether to generate a signed URL (default: `false`)
      # @option options [Integer, Float] :expires_in Expiration time in seconds for signed URLs
      #
      # @option options [Integer, String] :width Width attribute for the video tag
      # @option options [Integer, String] :height Height attribute for the video tag
      # @option options [String] :poster Poster image URL
      # @option options [String] :preload Preload strategy - `"none"`, `"metadata"`, or `"auto"`
      # @option options [Boolean] :controls Show video controls (default: `false`)
      # @option options [Boolean] :autoplay Autoplay the video (default: `false`)
      # @option options [Boolean] :loop Loop the video (default: `false`)
      # @option options [Boolean] :muted Mute the video (default: `false`)
      # @option options [String] :class CSS classes
      # @option options [Hash] :data Data attributes
      #
      # @return [String] HTML video tag with ImageKit URL
      #
      # @see https://www.gemdocs.org/gems/imagekitio/4.0.0/Imagekitio/Models/SrcOptions.html SrcOptions model
      # @see #ik_image_tag
      #
      # @example Basic usage
      #   ik_video_tag("/path/to/video.mp4", controls: true)
      #
      # @example With Active Storage
      #   ik_video_tag(post.video, controls: true)
      #
      # @example With transformations
      #   ik_video_tag(
      #     "/video.mp4",
      #     transformation: [{ width: 640, height: 480 }],
      #     controls: true
      #   )
      #
      # @example With poster image
      #   ik_video_tag(
      #     "/video.mp4",
      #     controls: true,
      #     poster: ik_url("/video.mp4/ik-thumbnail.jpg")
      #   )
      def ik_video_tag(src, options = {})
        # Handle Active Storage attachments
        original_src = src
        if active_storage_attachment?(src)
          return nil unless src.attached?

          original_src = src.blob.filename.to_s
          src = src.blob.key
        end

        raise ArgumentError, 'src is required' if src.nil? || src.empty?

        config = Imagekit::Rails.configuration
        helper = config.client.helper

        # Extract ImageKit-specific options
        url_endpoint = options.delete(:url_endpoint) || config.url_endpoint
        transformation = options.delete(:transformation) || []
        query_parameters = options.delete(:query_parameters)
        transformation_position = options.delete(:transformation_position) || config.transformation_position
        signed = options.delete(:signed)
        expires_in = options.delete(:expires_in)

        # Extract HTML attributes
        width = options.delete(:width)
        height = options.delete(:height)
        poster = options.delete(:poster)
        preload = options.delete(:preload)
        controls = options.delete(:controls)
        autoplay = options.delete(:autoplay)
        loop_video = options.delete(:loop)
        muted = options.delete(:muted)
        css_class = options.delete(:class)
        data_attributes = options.delete(:data)

        # Build video attributes
        video_attributes = {}

        # Add width and height if provided
        video_attributes[:width] = width if width
        video_attributes[:height] = height if height

        # Add poster if provided
        video_attributes[:poster] = poster if poster

        # Add preload if provided
        video_attributes[:preload] = preload if preload

        # Add boolean attributes
        video_attributes[:controls] = controls if controls
        video_attributes[:autoplay] = autoplay if autoplay
        video_attributes[:loop] = loop_video if loop_video
        video_attributes[:muted] = muted if muted

        # Add CSS class if provided
        video_attributes[:class] = css_class if css_class

        # Add data attributes if provided
        data_attributes&.each do |key, value|
          video_attributes[:"data-#{key}"] = value
        end

        # Add any remaining options as HTML attributes
        video_attributes.merge!(options)

        # Build video URL
        src_options = Imagekitio::Models::SrcOptions.new(
          src: src,
          url_endpoint: url_endpoint,
          transformation: transformation,
          transformation_position: transformation_position&.to_sym,
          query_parameters: query_parameters,
          signed: signed,
          expires_in: expires_in
        )

        video_url = helper.build_url(src_options)

        # Determine file extension for video type
        extension = if original_src == src
                      ::File.extname(src).delete('.')
                    else
                      ::File.extname(original_src).delete('.')
                    end

        # Generate the video tag with source
        content_tag(:video, video_attributes) do
          tag(:source, src: video_url, type: "video/#{extension}")
        end
      end

      private

      # Check if the object is an Active Storage attachment.
      #
      # @api private
      # @param obj [Object] Object to check
      # @return [Boolean] `true` if object is an ActiveStorage::Attached::One instance
      def active_storage_attachment?(obj)
        return false unless defined?(::ActiveStorage)
        return false unless defined?(::ActiveStorage::Attached)
        return false unless defined?(::ActiveStorage::Attached::One)

        obj.is_a?(::ActiveStorage::Attached::One)
      end
    end
  end
end
