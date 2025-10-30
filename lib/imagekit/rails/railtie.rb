# frozen_string_literal: true

require 'rails/railtie'

module Imagekit
  module Rails
    # Rails integration for ImageKit. Automatically includes view helpers and Active Storage callbacks.
    # @private
    class Railtie < ::Rails::Railtie
      initializer 'imagekit-rails.view_helpers' do
        ActiveSupport.on_load(:action_view) do
          include Imagekit::Rails::Helper
        end
      end

      if defined?(ActiveStorage)
        initializer 'imagekit-rails.active_storage', after: 'active_storage.services' do
          ActiveSupport.on_load(:active_storage_blob) do
            include Imagekit::Rails::ActiveStorage::BlobDeletionCallback
          end
        end
      end
    end
  end
end
