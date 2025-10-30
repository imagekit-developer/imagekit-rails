# frozen_string_literal: true

module Imagekit
  module Rails
    module ActiveStorage
      # Callback to handle ImageKit file deletion before blob is destroyed
      #
      # This concern is automatically included in ActiveStorage::Blob by the Railtie
      # and enables automatic deletion of files from ImageKit when blobs are purged.
      #
      # The callback runs **before** the blob is destroyed from the database, ensuring
      # access to the blob's metadata which contains the ImageKit file_id required for deletion.
      #
      # When a blob is destroyed (via purge, purge_later, or dependent destruction),
      # this callback intercepts the deletion and removes the file from ImageKit first,
      # then allows the blob record to be deleted from the database.
      #
      # @note This is automatically set up by the gem's Railtie - no manual configuration needed.
      #
      # @example Usage in your models
      #   class User < ApplicationRecord
      #     has_one_attached :avatar, dependent: :purge_later
      #   end
      #
      #   user.avatar.purge  # Automatically deletes from ImageKit then database
      #
      # @see Imagekit::Rails::ActiveStorage::Service#delete
      # @see Imagekit::Rails::Railtie
      # @private
      module BlobDeletionCallback
        extend ActiveSupport::Concern

        included do
          before_destroy :delete_from_imagekit, if: :imagekit_service?
        end

        private

        # Check if this blob uses ImageKit service and has a file_id
        #
        # @return [Boolean] true if blob should be deleted from ImageKit
        # @private
        def imagekit_service?
          service_name == 'imagekit' && metadata.key?('imagekit_file_id')
        end

        # Delete the file from ImageKit before the blob is destroyed
        #
        # This method is called as a before_destroy callback, ensuring we have
        # access to the blob's metadata to retrieve the ImageKit file_id.
        #
        # @return [void]
        # @private
        def delete_from_imagekit
          file_id = metadata['imagekit_file_id']
          return unless file_id

          begin
            # Get the ImageKit service instance
            imagekit_service = service

            if imagekit_service.is_a?(Imagekit::Rails::ActiveStorage::Service)
              # Call the ImageKit API directly
              imagekit_service.client.files.delete(file_id)
              ::Rails.logger.info("Deleted file from ImageKit: #{key} (file_id: #{file_id})") if defined?(::Rails)
            end
          rescue StandardError => e
            # Log but don't prevent blob deletion
            ::Rails.logger.warn("Failed to delete file from ImageKit: #{key} (file_id: #{file_id}): #{e.message}") if defined?(::Rails)
          end
        end
      end
    end
  end
end
