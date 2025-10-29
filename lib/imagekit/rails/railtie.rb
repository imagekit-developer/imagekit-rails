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
    end
  end
end
