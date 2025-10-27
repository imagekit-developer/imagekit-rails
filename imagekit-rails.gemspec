# frozen_string_literal: true

require_relative 'lib/imagekit/rails/version'

Gem::Specification.new do |s|
  s.name = 'imagekit-rails'
  s.version = Imagekit::Rails::VERSION
  s.summary = 'ImageKit Rails integration with view helpers and Active Storage support'
  s.description = 'Comprehensive Rails integration for ImageKit.io with view helpers (ik_image_tag, ik_video_tag) and Active Storage service adapter. Provides easy image optimization, transformation, and responsive image support.'
  s.authors = ['ImageKit']
  s.email = 'support@imagekit.io'
  s.homepage = 'https://github.com/imagekit-developer/imagekit-rails'
  s.license = 'MIT'
  s.metadata['homepage_uri'] = s.homepage
  s.metadata['source_code_uri'] = 'https://github.com/imagekit-developer/imagekit-rails'
  s.metadata['changelog_uri'] = 'https://github.com/imagekit-developer/imagekit-rails/blob/main/CHANGELOG.md'
  s.metadata['rubygems_mfa_required'] = 'false'
  s.required_ruby_version = '>= 3.0.0'

  s.files = Dir[
    'lib/**/*.rb',
    'LICENSE',
    'README.md',
    'CHANGELOG.md',
    'SUMMARY.md',
    'QUICKSTART.md',
    'API.md',
    'ACTIVE_STORAGE.md',
    'CONTRIBUTING.md'
  ]
  s.extra_rdoc_files = ['README.md']

  s.add_dependency 'rails', '>= 6.0'

  # NOTE: imagekit gem must be added to the user's Gemfile from GitHub
  # until it's published to RubyGems:
  #   gem 'imagekit', git: 'https://github.com/stainless-sdks/imagekit-ruby.git'

  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'rubocop', '~> 1.21'
end
