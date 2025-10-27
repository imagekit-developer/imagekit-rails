# frozen_string_literal: true

require 'rails/railtie'

module Imagekit
  module Rails
    class Railtie < ::Rails::Railtie
      initializer 'imagekit-rails.view_helpers' do
        ActiveSupport.on_load(:action_view) do
          include Imagekit::Rails::Helper
        end
      end

      # Register Active Storage service
      initializer 'imagekit-rails.active_storage' do
        ActiveSupport.on_load(:active_storage_blob) do
          require 'imagekit/rails/active_storage/attached_extensions'
        end
      end

      # Load configuration from Rails initializer if it exists
      config.before_configuration do
        config_file = ::Rails.root.join('config', 'imagekit.rb')
        load config_file if config_file.exist?
      end
    end
  end
end
