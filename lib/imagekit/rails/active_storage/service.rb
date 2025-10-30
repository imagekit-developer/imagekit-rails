# frozen_string_literal: true

require 'active_storage/service'
require 'tempfile'

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
        # @param checksum [String, nil] Optional MD5 checksum for integrity verification
        # @param filename [String, nil] Optional filename to use
        # @return [void]
        # @raise [ActiveStorage::IntegrityError] If upload fails
        # @note The ImageKit file_id is automatically stored in the blob's metadata after successful upload.
        #   This enables automatic deletion when the blob is purged.
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
            response = @client.files.upload(**upload_params)

            # Store the file_id in blob metadata for future deletion
            store_file_id_in_blob_metadata(key, response.file_id) if response.respond_to?(:file_id) && response.file_id
          end
        rescue Imagekit::Errors::Error => e
          raise ::ActiveStorage::IntegrityError, "Upload failed: #{e.message}"
        end

        # Download file content from ImageKit
        #
        # @param key [String] The unique identifier for the file
        # @yield [chunk] Streams file content in chunks if block given
        # @yieldparam chunk [String] A chunk of the file content
        # @return [String, void] The complete file content if no block given, void if block given
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

        # Override open to skip checksum verification for ImageKit
        #
        # ImageKit may serve optimized versions of files (format conversion, compression, etc.),
        # which causes the checksum to differ from the originally uploaded file.
        # This is safe because:
        # 1. ImageKit is a trusted CDN service
        # 2. Files are served over HTTPS
        # 3. The optimization is intentional behavior
        #
        # Note: This method is called by ActiveStorage when processing variants or
        # when blob.open is called (e.g., for image processing).
        #
        # @param key [String] The unique identifier for the file
        # @param checksum [String] The expected checksum (ignored for ImageKit)
        # @param name [String, Array] Basename for the temporary file (can be string or [basename, extension])
        # @param tmpdir [String, nil] Directory for the temporary file
        # @yield [tempfile] Provides access to the downloaded file
        # @yieldparam tempfile [Tempfile] The temporary file containing downloaded content
        # @return [void]
        def open(key, checksum:, name: 'ActiveStorage-', tmpdir: nil, **)
          instrument :open, key: key, checksum: checksum do
            # Create a temporary file to download into
            # ActiveStorage may pass name as a string or array [basename, extension]
            tempfile = Tempfile.open(name, tmpdir || Dir.tmpdir, binmode: true)

            begin
              # Download the file without checksum verification
              download(key) do |chunk|
                tempfile.write(chunk)
              end

              tempfile.rewind

              # Yield the tempfile to the caller
              yield tempfile
            ensure
              # Always clean up the tempfile
              tempfile.close!
            end
          end
        end

        # Download a byte range from the file
        #
        # @param key [String] The unique identifier for the file
        # @param range [Range] The byte range to download
        # @return [String] The requested chunk of file content
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
        # @return [void]
        # @note This method is called by Active Storage after the blob record is already deleted
        #   from the database, making it impossible to retrieve the file_id from metadata.
        #   Actual deletion is handled automatically by a before_destroy callback on the blob,
        #   which runs before the blob is destroyed and has access to the file_id in metadata.
        #   This method is a no-op that exists only to satisfy the Active Storage service interface.
        def delete(key)
          # No-op: Deletion is handled by BlobDeletionCallback before the blob is destroyed
          # This method is called after blob deletion, so we can't access metadata here
          ::Rails.logger.debug { "ImageKit delete called for key: #{key} (handled by before_destroy callback)" } if defined?(::Rails)
        end

        # Delete multiple files from ImageKit by prefix
        #
        # @param prefix [String] The prefix path to delete (e.g., "uploads/2024/")
        # @return [void]
        # @note This method is rarely used by Active Storage. Individual file deletions
        #   are handled automatically by a before_destroy callback on each blob.
        #   This method is called after blobs are already deleted from the database,
        #   so it cannot access blob metadata. This is a no-op that exists only to satisfy
        #   the Active Storage service interface.
        def delete_prefixed(prefix)
          # No-op: Deletion is handled by BlobDeletionCallback on individual blobs
          # This method is called after blobs are deleted, so we can't access metadata
          return unless defined?(::Rails)

          ::Rails.logger.debug do
            "ImageKit delete_prefixed called for prefix: #{prefix} (handled by before_destroy callback on individual blobs)"
          end
        end

        # Check if a file exists in ImageKit
        #
        # @param key [String] The unique identifier for the file
        # @return [Boolean]
        # @note Makes an API call to ImageKit to verify the file exists.
        #   Requires the imagekit_file_id to be stored in blob metadata.
        def exist?(key)
          instrument :exist, key: key do |payload|
            blob = find_blob_by_key(key)

            # If blob doesn't exist or has no file_id, file doesn't exist
            if blob.nil? || !blob.metadata.key?('imagekit_file_id')
              payload[:exist] = false
              payload[:reason] = blob.nil? ? 'blob_not_found' : 'file_id_missing'
              next false
            end

            file_id = blob.metadata['imagekit_file_id']

            begin
              # Try to get file details from ImageKit
              @client.files.get(file_id)
              payload[:exist] = true
              true
            rescue Imagekit::Errors::Error => e
              # File not found or other error
              payload[:exist] = false
              payload[:error] = e.message
              false
            end
          end
        end

        # Generate a URL for the file
        #
        # @param key [String] The unique identifier for the file
        # @param transformation [Array<Hash>, nil] ImageKit transformations
        # @return [String] The generated URL for the file
        # @see https://www.rubydoc.info/gems/imagekit/Imagekit/Models/Transformation Transformation options
        def url(key, transformation: nil, **)
          instrument :url, key: key do |payload|
            generated_url = url_for_key(key, transformation: transformation)
            payload[:url] = generated_url
            generated_url
          end
        end

        private

        # Build a URL for a file key with optional transformations
        #
        # @param key [String] The file path in ImageKit
        # @param transformation [Array<Hash>, nil] Optional transformations
        # @return [String] The complete ImageKit URL
        # @private
        def url_for_key(key, transformation: nil)
          # The key is the complete file path in ImageKit
          src_options = Imagekit::Models::SrcOptions.new(
            src: key,
            url_endpoint: @url_endpoint,
            transformation: transformation || []
          )

          @client.helper.build_url(src_options)
        end

        # Stream file content in chunks
        #
        # @param key [String] The file path in ImageKit
        # @yield [chunk] Yields each chunk of the file content
        # @yieldparam chunk [String] A chunk of file content
        # @return [void]
        # @private
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

        # Instrument an operation for Active Support notifications
        #
        # @param operation [Symbol] The operation name (e.g., :upload, :download)
        # @param payload [Hash] Additional data to include in the notification
        # @yield Block to execute with instrumentation
        # @return [Object] The result of the yielded block
        # @private
        def instrument(operation, payload = {}, &block)
          ActiveSupport::Notifications.instrument(
            "service_#{operation}.active_storage",
            payload.merge(service: service_name),
            &block
          )
        end

        # Return the service name for Active Storage instrumentation
        #
        # @return [Symbol] The service name (:imagekit)
        # @private
        def service_name
          :imagekit
        end

        # Find a blob by its key
        #
        # @param key [String] The blob key
        # @return [ActiveStorage::Blob, nil] The blob or nil if not found
        # @private
        def find_blob_by_key(key)
          return nil unless defined?(::ActiveStorage::Blob)

          ::ActiveStorage::Blob.find_by(key: key, service_name: service_name.to_s)
        end

        # Find all blobs with keys starting with the given prefix
        #
        # @param prefix [String] The key prefix
        # @return [ActiveRecord::Relation<ActiveStorage::Blob>] The matching blobs
        # @private
        def find_blobs_by_prefix(prefix)
          return [] unless defined?(::ActiveStorage::Blob)

          ::ActiveStorage::Blob.where(service_name: service_name.to_s)
                               .where('key LIKE ?', "#{sanitize_sql_like(prefix)}%")
        end

        # Sanitize string for use in SQL LIKE pattern
        #
        # @param string [String] The string to sanitize
        # @return [String] The sanitized string
        # @private
        def sanitize_sql_like(string)
          string.gsub(/[\\_%]/) { |match| "\\#{match}" }
        end

        # Store the ImageKit file_id in the blob's metadata
        #
        # @param key [String] The blob key
        # @param file_id [String] The ImageKit file_id
        # @return [void]
        # @private
        def store_file_id_in_blob_metadata(key, file_id)
          return unless defined?(::ActiveStorage::Blob)

          # Find the blob by key - it should exist since upload is called after blob creation
          blob = ::ActiveStorage::Blob.find_by(key: key, service_name: service_name.to_s)

          if blob
            # Update the metadata column to include the file_id
            # Use update_column to skip callbacks and validations
            blob.update_column(:metadata, blob.metadata.merge('imagekit_file_id' => file_id))
          end
        rescue StandardError => e
          # Log the error but don't fail the upload
          ::Rails.logger.warn("Failed to store ImageKit file_id for key #{key}: #{e.message}") if defined?(::Rails)
        end
      end
    end
  end
end
