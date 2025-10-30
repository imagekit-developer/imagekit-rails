# frozen_string_literal: true

require 'spec_helper'
require 'imagekitio-rails'

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
    context 'basic functionality' do
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
    end

    context 'with width and height' do
      it 'generates image with width only (DPR-based srcset with 1x, 2x)' do
        result = ik_image_tag('/test.jpg', width: 400, alt: 'With Width')

        expect(result).to eq(
          '<img alt="With Width" loading="lazy" width="400" ' \
          'src="https://ik.imagekit.io/test_account/test.jpg?tr=w-828,c-at_max" ' \
          'srcset="https://ik.imagekit.io/test_account/test.jpg?tr=w-640,c-at_max 1x, ' \
          'https://ik.imagekit.io/test_account/test.jpg?tr=w-828,c-at_max 2x" />'
        )
      end

      it 'generates image with width as string (should convert to integer)' do
        result = ik_image_tag('/test.jpg', width: '300', alt: 'Width as string')

        expect(result).to eq(
          '<img alt="Width as string" loading="lazy" width="300" ' \
          'src="https://ik.imagekit.io/test_account/test.jpg?tr=w-640,c-at_max" ' \
          'srcset="https://ik.imagekit.io/test_account/test.jpg?tr=w-384,c-at_max 1x, ' \
          'https://ik.imagekit.io/test_account/test.jpg?tr=w-640,c-at_max 2x" />'
        )
      end

      it 'generates image with width and height' do
        result = ik_image_tag('/test.jpg', width: 400, height: 300, alt: 'With Dimensions')

        expect(result).to eq(
          '<img alt="With Dimensions" loading="lazy" width="400" height="300" ' \
          'src="https://ik.imagekit.io/test_account/test.jpg?tr=w-828,c-at_max" ' \
          'srcset="https://ik.imagekit.io/test_account/test.jpg?tr=w-640,c-at_max 1x, ' \
          'https://ik.imagekit.io/test_account/test.jpg?tr=w-828,c-at_max 2x" />'
        )
      end
    end

    context 'with transformations' do
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

      it 'applies transformations with width and height attributes' do
        result = ik_image_tag(
          '/test.jpg',
          transformation: [{ width: 100, height: 100 }],
          width: 300,
          height: 300,
          alt: 'Transformed with dimensions'
        )

        expect(result).to eq(
          '<img alt="Transformed with dimensions" loading="lazy" width="300" height="300" ' \
          'src="https://ik.imagekit.io/test_account/test.jpg?tr=h-100,w-100:w-640,c-at_max" ' \
          'srcset="https://ik.imagekit.io/test_account/test.jpg?tr=h-100,w-100:w-384,c-at_max 1x, ' \
          'https://ik.imagekit.io/test_account/test.jpg?tr=h-100,w-100:w-640,c-at_max 2x" />'
        )
      end

      it 'applies named transformations' do
        result = ik_image_tag(
          '/test.jpg',
          transformation: [{ named: 'test-preset' }],
          width: 300,
          height: 300,
          responsive: false,
          alt: 'Named transformation'
        )

        expect(result).to eq(
          '<img alt="Named transformation" loading="lazy" width="300" height="300" ' \
          'src="https://ik.imagekit.io/test_account/test.jpg?tr=n-test-preset" />'
        )
      end
    end

    context 'with sizes attribute' do
      it 'generates responsive image with sizes containing vw' do
        result = ik_image_tag(
          '/test.jpg',
          sizes: '(max-width: 600px) 100vw, 50vw',
          width: 300,
          height: 300,
          alt: 'Responsive with sizes'
        )

        expect(result).to eq(
          '<img alt="Responsive with sizes" loading="lazy" width="300" height="300" ' \
          'src="https://ik.imagekit.io/test_account/test.jpg?tr=w-3840,c-at_max" ' \
          'srcset="https://ik.imagekit.io/test_account/test.jpg?tr=w-384,c-at_max 384w, ' \
          'https://ik.imagekit.io/test_account/test.jpg?tr=w-640,c-at_max 640w, ' \
          'https://ik.imagekit.io/test_account/test.jpg?tr=w-750,c-at_max 750w, ' \
          'https://ik.imagekit.io/test_account/test.jpg?tr=w-828,c-at_max 828w, ' \
          'https://ik.imagekit.io/test_account/test.jpg?tr=w-1080,c-at_max 1080w, ' \
          'https://ik.imagekit.io/test_account/test.jpg?tr=w-1200,c-at_max 1200w, ' \
          'https://ik.imagekit.io/test_account/test.jpg?tr=w-1920,c-at_max 1920w, ' \
          'https://ik.imagekit.io/test_account/test.jpg?tr=w-2048,c-at_max 2048w, ' \
          'https://ik.imagekit.io/test_account/test.jpg?tr=w-3840,c-at_max 3840w" ' \
          'sizes="(max-width: 600px) 100vw, 50vw" />'
        )
      end

      it 'generates responsive image with sizes not having vw token' do
        result = ik_image_tag(
          '/test.jpg',
          sizes: '300px',
          width: 300,
          height: 300,
          alt: 'Responsive with pixel sizes'
        )

        expect(result).to eq(
          '<img alt="Responsive with pixel sizes" loading="lazy" width="300" height="300" ' \
          'src="https://ik.imagekit.io/test_account/test.jpg?tr=w-3840,c-at_max" ' \
          'srcset="https://ik.imagekit.io/test_account/test.jpg?tr=w-16,c-at_max 16w, ' \
          'https://ik.imagekit.io/test_account/test.jpg?tr=w-32,c-at_max 32w, ' \
          'https://ik.imagekit.io/test_account/test.jpg?tr=w-48,c-at_max 48w, ' \
          'https://ik.imagekit.io/test_account/test.jpg?tr=w-64,c-at_max 64w, ' \
          'https://ik.imagekit.io/test_account/test.jpg?tr=w-96,c-at_max 96w, ' \
          'https://ik.imagekit.io/test_account/test.jpg?tr=w-128,c-at_max 128w, ' \
          'https://ik.imagekit.io/test_account/test.jpg?tr=w-256,c-at_max 256w, ' \
          'https://ik.imagekit.io/test_account/test.jpg?tr=w-384,c-at_max 384w, ' \
          'https://ik.imagekit.io/test_account/test.jpg?tr=w-640,c-at_max 640w, ' \
          'https://ik.imagekit.io/test_account/test.jpg?tr=w-750,c-at_max 750w, ' \
          'https://ik.imagekit.io/test_account/test.jpg?tr=w-828,c-at_max 828w, ' \
          'https://ik.imagekit.io/test_account/test.jpg?tr=w-1080,c-at_max 1080w, ' \
          'https://ik.imagekit.io/test_account/test.jpg?tr=w-1200,c-at_max 1200w, ' \
          'https://ik.imagekit.io/test_account/test.jpg?tr=w-1920,c-at_max 1920w, ' \
          'https://ik.imagekit.io/test_account/test.jpg?tr=w-2048,c-at_max 2048w, ' \
          'https://ik.imagekit.io/test_account/test.jpg?tr=w-3840,c-at_max 3840w" ' \
          'sizes="300px" />'
        )
      end
    end

    context 'responsive behavior' do
      it 'disables responsive images when specified' do
        result = ik_image_tag('/test.jpg', alt: 'Test', responsive: false)
        expect(result).to eq('<img alt="Test" loading="lazy" src="https://ik.imagekit.io/test_account/test.jpg" />')
      end

      it 'generates image without width (should use device breakpoints)' do
        result = ik_image_tag('/test.jpg', alt: 'No width')

        expect(result).to eq(
          '<img alt="No width" loading="lazy" ' \
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

      it 'uses custom device breakpoints' do
        result = ik_image_tag(
          '/test.jpg',
          alt: 'Custom breakpoints',
          device_breakpoints: [200, 400, 800]
        )

        expect(result).to eq(
          '<img alt="Custom breakpoints" loading="lazy" ' \
          'src="https://ik.imagekit.io/test_account/test.jpg?tr=w-800,c-at_max" ' \
          'srcset="https://ik.imagekit.io/test_account/test.jpg?tr=w-200,c-at_max 200w, ' \
          'https://ik.imagekit.io/test_account/test.jpg?tr=w-400,c-at_max 400w, ' \
          'https://ik.imagekit.io/test_account/test.jpg?tr=w-800,c-at_max 800w" ' \
          'sizes="100vw" />'
        )
      end

      it 'uses custom device and image breakpoints' do
        result = ik_image_tag(
          'https://ik.imagekit.io/demo/default-image.jpg',
          alt: 'Custom deviceBreakpoints',
          device_breakpoints: [200, 400, 800],
          image_breakpoints: [100]
        )

        # Image breakpoints are merged with device breakpoints, but filtered based on strategy
        # In this case without sizes/width, it uses device breakpoints strategy
        expect(result).to eq(
          '<img alt="Custom deviceBreakpoints" loading="lazy" ' \
          'src="https://ik.imagekit.io/demo/default-image.jpg?tr=w-800,c-at_max" ' \
          'srcset="https://ik.imagekit.io/demo/default-image.jpg?tr=w-200,c-at_max 200w, ' \
          'https://ik.imagekit.io/demo/default-image.jpg?tr=w-400,c-at_max 400w, ' \
          'https://ik.imagekit.io/demo/default-image.jpg?tr=w-800,c-at_max 800w" ' \
          'sizes="100vw" />'
        )
      end

      it 'does not generate srcset when responsive is false with sizes' do
        result = ik_image_tag(
          '/test.jpg',
          alt: 'Non-responsive',
          width: 300,
          height: 300,
          responsive: false,
          sizes: '(max-width: 600px) 100vw, 50vw'
        )

        expect(result).to eq('<img alt="Non-responsive" loading="lazy" width="300" height="300" src="https://ik.imagekit.io/test_account/test.jpg" />')
      end
    end

    context 'HTML attributes' do
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

    context 'transformation position' do
      it 'uses path transformation position' do
        result = ik_image_tag(
          '/test.jpg',
          alt: 'Path transformation',
          transformation_position: :path,
          responsive: false
        )

        expect(result).to eq('<img alt="Path transformation" loading="lazy" src="https://ik.imagekit.io/test_account/test.jpg" />')
      end

      it 'uses path transformation position with custom transformations' do
        result = ik_image_tag(
          '/test.jpg',
          alt: 'Path with transformations',
          transformation: [{ width: 100, height: 100 }],
          transformation_position: :path,
          responsive: false
        )

        expect(result).to eq('<img alt="Path with transformations" loading="lazy" src="https://ik.imagekit.io/test_account/tr:h-100,w-100/test.jpg" />')
      end

      it 'does not respect path with absolute URL' do
        result = ik_image_tag(
          'https://ik.imagekit.io/demo/default-image.jpg',
          alt: 'Absolute URL',
          transformation_position: :path,
          width: 300,
          height: 300,
          responsive: false
        )

        # Absolute URLs should use query params, not path
        expect(result).to eq('<img alt="Absolute URL" loading="lazy" width="300" height="300" src="https://ik.imagekit.io/demo/default-image.jpg" />')
      end
    end

    context 'with query parameters' do
      it 'adds query parameters' do
        result = ik_image_tag(
          '/test.jpg',
          alt: 'With query params',
          query_parameters: { version: 'v1' },
          transformation: [{ width: 100, height: 100 }],
          width: 300,
          height: 300,
          responsive: false
        )

        expect(result).to eq('<img alt="With query params" loading="lazy" width="300" height="300" src="https://ik.imagekit.io/test_account/test.jpg?version=v1&amp;tr=h-100,w-100" />')
      end
    end

    context 'URL endpoint override' do
      it 'uses overridden urlEndpoint' do
        result = ik_image_tag(
          '/test.jpg',
          url_endpoint: 'https://ik.imagekit.io/demo2',
          alt: 'Override endpoint',
          transformation: [{ width: 100, height: 100 }],
          width: 300,
          height: 300,
          responsive: false
        )

        expect(result).to eq('<img alt="Override endpoint" loading="lazy" width="300" height="300" src="https://ik.imagekit.io/demo2/test.jpg?tr=h-100,w-100" />')
      end
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

    it 'uses path transformation position' do
      result = ik_video_tag(
        '/test.mp4',
        transformation: [{ width: 100, height: 100 }],
        transformation_position: :path,
        width: 300,
        height: 300
      )

      expect(result).to eq('<video width="300" height="300"><source src="https://ik.imagekit.io/test_account/tr:h-100,w-100/test.mp4" type="video/mp4" /></video>')
    end

    it 'uses overridden urlEndpoint' do
      result = ik_video_tag(
        '/test.mp4',
        url_endpoint: 'https://ik.imagekit.io/demo2',
        transformation: [{ width: 100, height: 100 }],
        width: 300,
        height: 300,
        controls: true
      )

      expect(result).to eq('<video width="300" height="300" controls="controls"><source src="https://ik.imagekit.io/demo2/test.mp4?tr=h-100,w-100" type="video/mp4" /></video>')
    end
  end
end
