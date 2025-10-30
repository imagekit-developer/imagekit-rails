# frozen_string_literal: true

require_relative 'lib/imagekit/rails/version'

Gem::Specification.new do |s|
  s.name = 'imagekitio-rails'
  s.version = Imagekit::Rails::VERSION
  s.summary = 'ImageKit Rails integration with view helpers and Active Storage support'
  s.description = 'Comprehensive Rails integration for ImageKit.io with view helpers (ik_image_tag, ik_video_tag) and Active Storage service adapter. Provides easy image optimization, transformation, and responsive image support.'
  s.authors = ['ImageKit']
  s.email = 'support@imagekit.io'
  s.homepage = 'https://github.com/imagekit-developer/imagekit-rails'
  s.license = 'Apache-2.0'
  s.metadata['homepage_uri'] = s.homepage
  s.metadata['source_code_uri'] = 'https://github.com/imagekit-developer/imagekit-rails'
  s.metadata['rubygems_mfa_required'] = false.to_s
  s.required_ruby_version = '>= 3.2.0'

  s.files = Dir[
    'lib/**/*.rb',
    'LICENSE',
    'README.md',
    'CHANGELOG.md',
    'SUMMARY.md',
    'QUICKSTART.md',
    'API.md',
    'ACTIVE_STORAGE.md',
    'CHANGELOG.md',
    'CONTRIBUTING.md'
  ]
  s.extra_rdoc_files = ['README.md']

  s.add_dependency 'rails', '>= 6.0'

  # NOTE: imagekitio gem must be added to the user's Gemfile from GitHub
  # until it's published to RubyGems:
  #   gem 'imagekitio', git: 'https://github.com/imagekit-developer/imagekit-ruby.git', branch: 'next'

  s.add_development_dependency 'redcarpet', '~> 3.6' # For markdown in YARD
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'rubocop', '~> 1.21'
  s.add_development_dependency 'webrick', '~> 1.8' # For YARD server
  s.add_development_dependency 'yard', '~> 0.9'
end
