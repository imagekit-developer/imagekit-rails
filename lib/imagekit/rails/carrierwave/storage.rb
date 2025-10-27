# frozen_string_literal: true

require 'carrierwave'

module Imagekit
  module Rails
    module CarrierWave
      # CarrierWave storage adapter for ImageKit
      #
      # Usage in your uploader:
      #
      #   class AvatarUploader < CarrierWave::Uploader::Base
      #     storage :imagekit
      #
      #     def store_dir
      #       "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
      #     end
      #   end
      #
      # Configuration:
      #
      #   CarrierWave.configure do |config|
      #     config.imagekit_url_endpoint = ENV['IMAGEKIT_URL_ENDPOINT']
      #     config.imagekit_public_key = ENV['IMAGEKIT_PUBLIC_KEY']
      #     config.imagekit_private_key = ENV['IMAGEKIT_PRIVATE_KEY']
      #   end
      class Storage < ::CarrierWave::Storage::Abstract
        def store!(file)
          f = ImagekitFile.new(uploader, uploader.store_path)
          f.store(file)
          f
        end

        def retrieve!(identifier)
          ImagekitFile.new(uploader, uploader.store_path(identifier))
        end

        def client
          @client ||= Imagekit::Client.new(
            private_key: uploader.imagekit_private_key,
            public_key: uploader.imagekit_public_key,
            base_url: uploader.imagekit_url_endpoint
          )
        end

        class ImagekitFile
          attr_reader :uploader, :path

          def initialize(uploader, path)
            @uploader = uploader
            @path = path
          end

          def store(new_file)
            content = new_file.read

            client.file.upload(
              file: content,
              file_name: ::File.basename(path),
              folder: ::File.dirname(path),
              use_unique_file_name: false,
              tags: ['carrierwave']
            )
          end

          def read
            response = Net::HTTP.get_response(URI(url))
            response.body
          end

          def delete
            file = find_file
            client.file.delete(file_id: file.file_id) if file
          rescue Imagekit::Error
            # File might not exist
            true
          end

          def exists?
            find_file.present?
          rescue Imagekit::Error
            false
          end

          def size
            file = find_file
            file&.size || 0
          end

          def content_type
            file = find_file
            file&.mime_type
          end

          def filename
            ::File.basename(path)
          end

          def extension
            ::File.extname(path).delete('.')
          end

          def url(transformation: nil, signed: false, expires_in: nil)
            src_options = Imagekit::Models::SrcOptions.new(
              src: path,
              url_endpoint: uploader.imagekit_url_endpoint,
              transformation: transformation || [],
              signed: signed,
              expires_in: expires_in
            )

            client.helper.build_url(src_options)
          end

          private

          def client
            @client ||= Imagekit::Client.new(
              private_key: uploader.imagekit_private_key,
              public_key: uploader.imagekit_public_key,
              base_url: uploader.imagekit_url_endpoint
            )
          end

          def find_file
            folder_path = ::File.dirname(path)
            filename = ::File.basename(path)

            files = client.file.list(
              path: folder_path,
              search_query: "name:\"#{filename}\""
            )

            files.first
          end
        end
      end
    end
  end
end

# Extend CarrierWave configuration
module CarrierWave
  module Uploader
    class Base
      # ImageKit configuration accessors
      def self.imagekit_url_endpoint
        @imagekit_url_endpoint || Imagekit::Rails.configuration.url_endpoint
      end

      def self.imagekit_public_key
        @imagekit_public_key || Imagekit::Rails.configuration.public_key
      end

      def self.imagekit_private_key
        @imagekit_private_key || Imagekit::Rails.configuration.private_key
      end

      class << self
        attr_writer :imagekit_url_endpoint
      end

      class << self
        attr_writer :imagekit_public_key
      end

      class << self
        attr_writer :imagekit_private_key
      end

      # Instance accessors
      def imagekit_url_endpoint
        self.class.imagekit_url_endpoint
      end

      def imagekit_public_key
        self.class.imagekit_public_key
      end

      def imagekit_private_key
        self.class.imagekit_private_key
      end
    end
  end
end

# Register the storage with CarrierWave
CarrierWave::Uploader::Base.storage_engines[:imagekit] = 'Imagekit::Rails::CarrierWave::Storage'
