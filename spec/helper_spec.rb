# frozen_string_literal: true

require 'spec_helper'
require 'imagekit-rails'

RSpec.describe Imagekit::Rails::Helper do
  include Imagekit::Rails::Helper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::OutputSafetyHelper
  include ActionView::Context

  before do
    Imagekit::Rails.configure do |config|
      config.url_endpoint = 'https://ik.imagekit.io/test_account'
      config.private_key = 'private_test_key'
      # Use defaults: responsive = true, device_breakpoints = [640, 750, 828, 1080, 1200, 1920, 2048, 3840]
    end
  end

  after do
    Imagekit::Rails.reset_configuration!
  end

  describe '#ik_image_tag' do
    it 'generates a basic image tag with responsive srcset' do
      result = ik_image_tag('/test.jpg', alt: 'Test Image')

      expect(result).to eq(
        '<img alt="Test Image" loading="lazy" ' \
        'src="https://ik.imagekit.io/test_account/test.jpg?tr=w-3840,c-at_max" ' \
        'srcset="https://ik.imagekit.io/test_account/test.jpg?tr=w-640,c-at_max 640w, ' \
        'https://ik.imagekit.io/test_account/test.jpg?tr=w-750,c-at_max 750w, ' \
        'https://ik.imagekit.io/test_account/test.jpg?tr=w-828,c-at_max 828w, ' \
        'https://ik.imagekit.io/test_account/test.jpg?tr=w-1080,c-at_max 1080w, ' \
        'https://ik.imagekit.io/test_account/test.jpg?tr=w-1200,c-at_max 1200w, ' \
        'https://ik.imagekit.io/test_account/test.jpg?tr=w-1920,c-at_max 1920w, ' \
        'https://ik.imagekit.io/test_account/test.jpg?tr=w-2048,c-at_max 2048w, ' \
        'https://ik.imagekit.io/test_account/test.jpg?tr=w-3840,c-at_max 3840w" ' \
        'sizes="100vw" />'
      )
    end

    it 'raises error when src is missing' do
      expect { ik_image_tag(nil) }.to raise_error(ArgumentError, 'src is required')
    end

    it 'applies transformations with responsive srcset' do
      result = ik_image_tag(
        '/test.jpg',
        transformation: [{ width: 400, height: 300 }],
        alt: 'Transformed'
      )

      expect(result).to eq(
        '<img alt="Transformed" loading="lazy" ' \
        'src="https://ik.imagekit.io/test_account/test.jpg?tr=h-300,w-400:w-3840,c-at_max" ' \
        'srcset="https://ik.imagekit.io/test_account/test.jpg?tr=h-300,w-400:w-640,c-at_max 640w, ' \
        'https://ik.imagekit.io/test_account/test.jpg?tr=h-300,w-400:w-750,c-at_max 750w, ' \
        'https://ik.imagekit.io/test_account/test.jpg?tr=h-300,w-400:w-828,c-at_max 828w, ' \
        'https://ik.imagekit.io/test_account/test.jpg?tr=h-300,w-400:w-1080,c-at_max 1080w, ' \
        'https://ik.imagekit.io/test_account/test.jpg?tr=h-300,w-400:w-1200,c-at_max 1200w, ' \
        'https://ik.imagekit.io/test_account/test.jpg?tr=h-300,w-400:w-1920,c-at_max 1920w, ' \
        'https://ik.imagekit.io/test_account/test.jpg?tr=h-300,w-400:w-2048,c-at_max 2048w, ' \
        'https://ik.imagekit.io/test_account/test.jpg?tr=h-300,w-400:w-3840,c-at_max 3840w" ' \
        'sizes="100vw" />'
      )
    end

    it 'disables responsive images when specified' do
      result = ik_image_tag('/test.jpg', alt: 'Test', responsive: false)
      expect(result).to eq('<img alt="Test" loading="lazy" src="https://ik.imagekit.io/test_account/test.jpg" />')
    end

    it 'respects loading attribute' do
      result = ik_image_tag('/test.jpg', alt: 'Test', loading: 'eager', responsive: false)
      expect(result).to eq('<img alt="Test" loading="eager" src="https://ik.imagekit.io/test_account/test.jpg" />')
    end

    it 'adds CSS classes' do
      result = ik_image_tag('/test.jpg', alt: 'Test', class: 'img-fluid rounded', responsive: false)
      expect(result).to eq('<img alt="Test" loading="lazy" class="img-fluid rounded" src="https://ik.imagekit.io/test_account/test.jpg" />')
    end

    it 'adds data attributes' do
      result = ik_image_tag('/test.jpg', alt: 'Test', data: { id: 123, action: 'click' }, responsive: false)
      expect(result).to eq('<img alt="Test" loading="lazy" data-id="123" data-action="click" src="https://ik.imagekit.io/test_account/test.jpg" />')
    end
  end

  describe '#ik_video_tag' do
    it 'generates a basic video tag' do
      result = ik_video_tag('/test.mp4')
      expect(result).to eq('<video><source src="https://ik.imagekit.io/test_account/test.mp4" type="video/mp4" /></video>')
    end

    it 'raises error when src is missing' do
      expect { ik_video_tag(nil) }.to raise_error(ArgumentError, 'src is required')
    end

    it 'applies transformations' do
      result = ik_video_tag(
        '/test.mp4',
        transformation: [{ width: 640, height: 480 }],
        controls: true
      )
      expect(result).to eq('<video controls="controls"><source src="https://ik.imagekit.io/test_account/test.mp4?tr=h-480,w-640" type="video/mp4" /></video>')
    end

    it 'adds video attributes' do
      result = ik_video_tag(
        '/test.mp4',
        controls: true,
        autoplay: true,
        loop: true,
        muted: true
      )
      expect(result).to eq('<video controls="controls" autoplay="autoplay" loop="loop" muted="muted"><source src="https://ik.imagekit.io/test_account/test.mp4" type="video/mp4" /></video>')
    end

    it 'adds poster attribute' do
      result = ik_video_tag('/test.mp4', poster: 'https://example.com/poster.jpg', controls: true)
      expect(result).to eq('<video poster="https://example.com/poster.jpg" controls="controls"><source src="https://ik.imagekit.io/test_account/test.mp4" type="video/mp4" /></video>')
    end

    it 'adds CSS classes' do
      result = ik_video_tag('/test.mp4', class: 'video-player', controls: true)
      expect(result).to eq('<video controls="controls" class="video-player"><source src="https://ik.imagekit.io/test_account/test.mp4" type="video/mp4" /></video>')
    end
  end
end
