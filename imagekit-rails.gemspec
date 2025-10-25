# frozen_string_literal: true

require_relative 'lib/imagekit/rails/version'

Gem::Specification.new do |spec|
  spec.name = 'imagekit-rails'
  spec.version = Imagekit::Rails::VERSION
  spec.authors = ['ImageKit']
  spec.email = ['support@imagekit.io']

  spec.summary = 'ImageKit Rails integration with view helpers'
  spec.description = 'Rails view helpers for ImageKit.io that provide easy image optimization, transformation, and responsive image support similar to ImageKit React SDK'
  spec.homepage = 'https://github.com/imagekit-developer/imagekit-rails'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/imagekit-developer/imagekit-rails'
  spec.metadata['changelog_uri'] = 'https://github.com/imagekit-developer/imagekit-rails/blob/main/CHANGELOG.md'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Dependencies
  # Note: imagekit gem is currently available at https://github.com/stainless-sdks/imagekit-ruby
  # Users will need to add it from GitHub in their Gemfile until it's published to RubyGems
  spec.add_dependency 'rails', '>= 6.0'

  # Development dependencies
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 1.21'
end
