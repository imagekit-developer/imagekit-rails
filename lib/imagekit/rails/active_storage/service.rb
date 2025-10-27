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
      #     url_endpoint: <%= ENV['IMAGEKIT_URL_ENDPOINT'] %>
      #     public_key: <%= ENV['IMAGEKIT_PUBLIC_KEY'] %>
      #     private_key: <%= ENV['IMAGEKIT_PRIVATE_KEY'] %>
      #     folder: "uploads" # optional, default folder for uploads
      class Service < ::ActiveStorage::Service
        attr_reader :client, :url_endpoint, :public_key, :private_key, :folder

        def initialize(url_endpoint:, public_key:, private_key:, folder: nil, **)
          super()
          @url_endpoint = url_endpoint
          @public_key = public_key
          @private_key = private_key
          @folder = folder
          @client = Imagekit::Client.new(
            private_key: private_key,
            public_key: public_key,
            base_url: url_endpoint
          )
        end

        # Upload a file to ImageKit
        #
        # @param key [String] The unique identifier for the file
        # @param io [IO] The file content to upload
        # @param checksum [String] Optional MD5 checksum for integrity verification
        def upload(key, io, checksum: nil, content_type: nil, filename: nil, custom_metadata: {}, **)
          instrument :upload, key: key, checksum: checksum do
            # Read the file content
            content = io.read
            io.rewind if io.respond_to?(:rewind)

            # Upload to ImageKit
            response = @client.file.upload(
              file: content,
              file_name: filename || ::File.basename(key),
              folder: folder_for(key),
              use_unique_file_name: false,
              tags: ['active_storage'],
              custom_metadata: custom_metadata.merge(
                checksum: checksum,
                content_type: content_type
              ).compact
            )

            # Store the file_id for later retrieval
            response
          end
        rescue Imagekit::Error => e
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
              url = url_for_key(key, expires_in: 300)
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
            url = url_for_key(key, expires_in: 300)
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
            # Find the file by name/path
            file = find_file(key)
            @client.file.delete(file_id: file.file_id) if file
          end
        rescue Imagekit::Error
          # File might not exist, which is fine for delete
          true
        end

        # Delete multiple files from ImageKit
        #
        # @param keys [Array<String>] The unique identifiers for the files
        def delete_prefixed(prefix)
          instrument :delete_prefixed, prefix: prefix do
            # List all files with the prefix
            folder_path = folder_for(prefix)
            files = @client.file.list(path: folder_path)

            files.each do |file|
              @client.file.delete(file_id: file.file_id)
            end
          end
        rescue Imagekit::Error
          # Ignore errors during bulk delete
          true
        end

        # Check if a file exists in ImageKit
        #
        # @param key [String] The unique identifier for the file
        # @return [Boolean]
        def exist?(key)
          instrument :exist, key: key do |payload|
            file = find_file(key)
            answer = file.present?
            payload[:exist] = answer
            answer
          end
        rescue Imagekit::Error
          false
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

        private

        def path_for(key)
          if folder
            "#{folder}/#{key}"
          else
            key
          end
        end

        def folder_for(key)
          if folder
            path = "#{folder}/#{key}"
            ::File.dirname(path)
          else
            ::File.dirname(key)
          end
        end

        def url_for_key(key, expires_in: nil, transformation: nil)
          path = path_for(key)

          src_options = Imagekit::Models::SrcOptions.new(
            src: path,
            url_endpoint: @url_endpoint,
            transformation: transformation || [],
            signed: expires_in.present?,
            expires_in: expires_in
          )

          @client.helper.build_url(src_options)
        end

        def find_file(key)
          # Search for file by name in the folder
          folder_path = folder_for(key)
          filename = ::File.basename(key)

          files = @client.file.list(
            path: folder_path,
            search_query: "name:\"#{filename}\""
          )

          files.first
        end

        def stream(key, &block)
          url = url_for_key(key, expires_in: 300)
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
