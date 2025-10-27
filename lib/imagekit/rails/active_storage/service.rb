# frozen_string_literal: true

require 'active_storage/service'

module Imagekit
  module Rails
    module ActiveStorage
      # Active Storage service for ImageKit
      #
      # Stores files in ImageKit and provides URL generation with transformations
      #
      # Configuration in config/storage.yml:
      #
      #   imagekit:
      #     service: ImageKit
      #
      # Note: url_endpoint, public_key, and private_key are read from
      # the global Imagekit::Rails.configuration (config/initializers/imagekit.rb)
      #
      # The Active Storage 'key' is used as the complete file path in ImageKit.
      # Active Storage generates unique keys that include any necessary folder structure.
      #
      # All files are uploaded as public files in ImageKit.
      class Service < ::ActiveStorage::Service
        attr_reader :client, :url_endpoint, :public_key, :private_key

        def initialize(url_endpoint: nil, public_key: nil, private_key: nil, **)
          super()

          # Use provided values or fall back to global configuration
          config = Imagekit::Rails.configuration
          @url_endpoint = url_endpoint || config.url_endpoint
          @public_key = public_key || config.public_key
          @private_key = private_key || config.private_key

          @client = Imagekit::Client.new(
            private_key: @private_key
          )
        end

        # Upload a file to ImageKit
        #
        # @param key [String] The complete path for the file in ImageKit (e.g., "uploads/abc123xyz")
        # @param io [IO] The file content to upload
        # @param checksum [String] Optional MD5 checksum for integrity verification
        def upload(key, io, checksum: nil, filename: nil, **)
          instrument :upload, key: key, checksum: checksum do
            # Read the file content
            content = io.read
            io.rewind if io.respond_to?(:rewind)

            # Extract folder and filename from the key
            # The key is the complete path: "folder/subfolder/filename"
            folder_path = ::File.dirname(key)
            file_name = filename || ::File.basename(key)

            # Build upload parameters
            upload_params = {
              file: content,
              file_name: file_name,
              use_unique_file_name: false
            }

            # Only include folder if there is one (don't pass nil or '.')
            upload_params[:folder] = folder_path unless folder_path == '.'

            # Upload to ImageKit - the key determines the full path
            @client.files.upload(**upload_params)

            # Active Storage doesn't use the response, it tracks files by the key parameter
          end
        rescue Imagekit::Errors::BaseError => e
          raise ::ActiveStorage::IntegrityError, "Upload failed: #{e.message}"
        end

        # Download file content from ImageKit
        #
        # @param key [String] The unique identifier for the file
        # @param &block [Block] Optional block to stream the content
        def download(key, &block)
          if block_given?
            instrument :streaming_download, key: key do
              stream(key, &block)
            end
          else
            instrument :download, key: key do
              url = url_for_key(key)
              response = Net::HTTP.get_response(URI(url))
              response.body
            end
          end
        end

        # Download a byte range from the file
        #
        # @param key [String] The unique identifier for the file
        # @param range [Range] The byte range to download
        def download_chunk(key, range)
          instrument :download_chunk, key: key, range: range do
            url = url_for_key(key)
            uri = URI(url)

            Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
              request = Net::HTTP::Get.new(uri)
              request['Range'] = "bytes=#{range.begin}-#{range.end}"
              response = http.request(request)
              response.body
            end
          end
        end

        # Delete a file from ImageKit
        #
        # @param key [String] The unique identifier for the file
        def delete(key)
          instrument :delete, key: key do
            # TODO: ImageKit requires file_id to delete files
            # We would need to search for the file first to get its file_id
            # For now, deletion is not implemented
            # Files can be manually deleted from ImageKit dashboard
          end
        end

        # Delete multiple files from ImageKit
        #
        # @param prefix [String] The prefix path to delete
        def delete_prefixed(prefix)
          instrument :delete_prefixed, prefix: prefix do
            # TODO: ImageKit requires file_id to delete files
            # Bulk deletion would require listing files first and then deleting each by file_id
            # For now, deletion is not implemented
            # Files can be manually deleted from ImageKit dashboard
          end
        end

        # Check if a file exists in ImageKit
        #
        # @param key [String] The unique identifier for the file
        # @return [Boolean]
        def exist?(key)
          instrument :exist, key: key do |payload|
            # TODO: ImageKit requires searching by file_id or listing files
            # For now, we assume files exist after successful upload
            # Active Storage will handle missing files via download errors
            answer = true
            payload[:exist] = answer
            answer
          end
        end

        # Generate a URL for the file
        #
        # @param key [String] The unique identifier for the file
        # @param expires_in [Integer] Expiration time in seconds
        # @param disposition [Symbol] Content disposition (:inline or :attachment)
        # @param filename [ActiveStorage::Filename] The filename to use
        # @param content_type [String] The content type
        # @param transformation [Array<Hash>] ImageKit transformations
        def url_for_direct_upload(key, expires_in:, content_type:, content_length:, **)
          instrument :url, key: key do |payload|
            # Generate authentication parameters for direct upload
            authenticated_params = @client.helper.get_authentication_parameters(
              token: SecureRandom.hex(16),
              expire: Time.now.to_i + expires_in
            )

            payload[:url] = "#{@url_endpoint}/api/v1/files/upload"

            {
              url: "#{@url_endpoint}/api/v1/files/upload",
              headers: {
                'Content-Type' => content_type,
                'Content-Length' => content_length.to_s
              }.merge(authenticated_params.transform_keys(&:to_s))
            }
          end
        end

        # Generate headers for direct upload
        def headers_for_direct_upload(_key, content_type:, checksum:, **)
          {
            'Content-Type' => content_type,
            'Content-MD5' => checksum
          }
        end

        # Generate a URL for the file
        #
        # @param key [String] The unique identifier for the file
        # @param _expires_in [Integer] Optional expiration time in seconds (not used, ImageKit files are public)
        # @param _filename [ActiveStorage::Filename] The filename to use (not used)
        # @param _disposition [Symbol] Content disposition (not used)
        # @param _content_type [String] The content type (not used)
        # @param transformation [Array<Hash>] ImageKit transformations
        def url(key, expires_in: nil, filename: nil, disposition: nil, content_type: nil, transformation: nil, **)
          instrument :url, key: key do |payload|
            generated_url = url_for_key(key, transformation: transformation)
            payload[:url] = generated_url
            generated_url
          end
        end

        private

        def url_for_key(key, transformation: nil)
          # The key is the complete file path in ImageKit
          src_options = Imagekit::Models::SrcOptions.new(
            src: key,
            url_endpoint: @url_endpoint,
            transformation: transformation || []
          )

          @client.helper.build_url(src_options)
        end

        def stream(key, &block)
          url = url_for_key(key)
          uri = URI(url)

          Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
            request = Net::HTTP::Get.new(uri)
            http.request(request) do |response|
              response.read_body(&block)
            end
          end
        end

        def instrument(operation, payload = {}, &block)
          ActiveSupport::Notifications.instrument(
            "service_#{operation}.active_storage",
            payload.merge(service: service_name),
            &block
          )
        end

        def service_name
          :imagekit
        end
      end
    end
  end
end
