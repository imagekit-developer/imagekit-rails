# frozen_string_literal: true

require 'spec_helper'
require 'imagekit-rails'
require 'active_support/notifications'
require 'net/http'
require 'imagekit/rails/active_storage/service'
require 'active_storage/service/image_kit_service'

# Mock ActiveStorage logger and IntegrityError for tests
module ActiveStorage
  def self.logger
    @logger ||= Logger.new(nil)
  end

  class IntegrityError < StandardError; end
end

RSpec.describe Imagekit::Rails::ActiveStorage::Service do
  let(:service) do
    described_class.new(
      url_endpoint: 'https://ik.imagekit.io/test_account',
      public_key: 'public_test_key',
      private_key: 'private_test_key'
    )
  end

  let(:mock_client) { instance_double(Imagekit::Client) }
  let(:mock_files) { instance_double('Files') }
  let(:mock_helper) { instance_double('Helper') }

  before do
    allow(Imagekit::Client).to receive(:new).and_return(mock_client)
    allow(mock_client).to receive(:files).and_return(mock_files)
    allow(mock_client).to receive(:helper).and_return(mock_helper)
  end

  describe '#initialize' do
    it 'initializes with explicit credentials' do
      service = described_class.new(
        url_endpoint: 'https://ik.imagekit.io/test1',
        public_key: 'pk_test',
        private_key: 'pr_test'
      )

      expect(service.url_endpoint).to eq('https://ik.imagekit.io/test1')
      expect(service.public_key).to eq('pk_test')
      expect(service.private_key).to eq('pr_test')
    end

    it 'falls back to global configuration' do
      Imagekit::Rails.configure do |config|
        config.url_endpoint = 'https://ik.imagekit.io/global'
        config.public_key = 'global_public_key'
        config.private_key = 'global_private_key'
      end

      service = described_class.new

      expect(service.url_endpoint).to eq('https://ik.imagekit.io/global')
      expect(service.public_key).to eq('global_public_key')
      expect(service.private_key).to eq('global_private_key')

      Imagekit::Rails.reset_configuration!
    end

    it 'creates an ImageKit client' do
      expect(Imagekit::Client).to receive(:new).with(
        private_key: 'private_test_key'
      )

      described_class.new(
        url_endpoint: 'https://ik.imagekit.io/test_account',
        public_key: 'public_test_key',
        private_key: 'private_test_key'
      )
    end
  end

  describe '#upload' do
    let(:io) { StringIO.new('file content') }
    let(:key) { 'uploads/test/file.jpg' }

    it 'uploads a file with folder and filename extracted from key' do
      expect(mock_files).to receive(:upload).with(
        file: 'file content',
        file_name: 'file.jpg',
        use_unique_file_name: false,
        folder: 'uploads/test'
      )

      service.upload(key, io)
    end

    it 'uploads a file without folder when key has no directory' do
      key = 'file.jpg'
      expect(mock_files).to receive(:upload).with(
        file: 'file content',
        file_name: 'file.jpg',
        use_unique_file_name: false
      )

      service.upload(key, io)
    end

    it 'uses provided filename parameter' do
      expect(mock_files).to receive(:upload).with(
        file: 'file content',
        file_name: 'custom_name.jpg',
        use_unique_file_name: false,
        folder: 'uploads/test'
      )

      service.upload(key, io, filename: 'custom_name.jpg')
    end

    it 'rewinds the IO after reading' do
      expect(io).to receive(:rewind)
      allow(mock_files).to receive(:upload)

      service.upload(key, io)
    end

    it 'raises IntegrityError when upload fails' do
      error = Imagekit::Errors::Error.new('Upload failed')
      allow(mock_files).to receive(:upload).and_raise(error)

      expect do
        service.upload(key, io)
      end.to raise_error(ActiveStorage::IntegrityError, /Upload failed/)
    end

    it 'instruments the upload' do
      allow(mock_files).to receive(:upload)
      expect(ActiveSupport::Notifications).to receive(:instrument).with(
        'service_upload.active_storage',
        hash_including(key: key, service: :imagekit)
      ).and_call_original

      service.upload(key, io)
    end
  end

  describe '#download' do
    let(:key) { 'uploads/test/file.jpg' }
    let(:url) { 'https://ik.imagekit.io/test_account/uploads/test/file.jpg' }

    before do
      allow(mock_helper).to receive(:build_url).and_return(url)
    end

    it 'downloads file content' do
      response = instance_double(Net::HTTPResponse, body: 'file content')
      allow(Net::HTTP).to receive(:get_response).with(URI(url)).and_return(response)

      result = service.download(key)
      expect(result).to eq('file content')
    end

    it 'streams file content when block is given' do
      http = instance_double(Net::HTTP)
      request = instance_double(Net::HTTPRequest)
      response = instance_double(Net::HTTPResponse)

      allow(Net::HTTP).to receive(:start).and_yield(http)
      allow(Net::HTTP::Get).to receive(:new).and_return(request)
      allow(http).to receive(:request).and_yield(response)
      allow(response).to receive(:read_body).and_yield('chunk1').and_yield('chunk2')

      chunks = []
      service.download(key) { |chunk| chunks << chunk }

      expect(chunks).to eq(%w[chunk1 chunk2])
    end

    it 'instruments the download' do
      response = instance_double(Net::HTTPResponse, body: 'file content')
      allow(Net::HTTP).to receive(:get_response).and_return(response)

      expect(ActiveSupport::Notifications).to receive(:instrument).with(
        'service_download.active_storage',
        hash_including(key: key, service: :imagekit)
      ).and_call_original

      service.download(key)
    end

    it 'instruments streaming download when block is given' do
      http = instance_double(Net::HTTP)
      request = instance_double(Net::HTTPRequest)
      response = instance_double(Net::HTTPResponse)

      allow(Net::HTTP).to receive(:start).and_yield(http)
      allow(Net::HTTP::Get).to receive(:new).and_return(request)
      allow(http).to receive(:request).and_yield(response)
      allow(response).to receive(:read_body)

      expect(ActiveSupport::Notifications).to receive(:instrument).with(
        'service_streaming_download.active_storage',
        hash_including(key: key, service: :imagekit)
      ).and_call_original

      service.download(key) { |_chunk| nil }
    end
  end

  describe '#open' do
    let(:key) { 'uploads/test/file.jpg' }
    let(:url) { 'https://ik.imagekit.io/test_account/uploads/test/file.jpg' }
    let(:checksum) { 'abc123' }

    before do
      allow(mock_helper).to receive(:build_url).and_return(url)
    end

    it 'downloads file to tempfile and yields it' do
      http = instance_double(Net::HTTP)
      request = instance_double(Net::HTTP::Get)
      response = instance_double(Net::HTTPResponse)

      allow(Net::HTTP).to receive(:start).and_yield(http)
      allow(Net::HTTP::Get).to receive(:new).and_return(request)
      allow(http).to receive(:request).and_yield(response)
      allow(response).to receive(:read_body).and_yield('file').and_yield(' content')

      result = nil
      service.open(key, checksum: checksum) do |tempfile|
        result = tempfile.read
      end

      expect(result).to eq('file content')
    end

    it 'ignores checksum parameter (no verification)' do
      http = instance_double(Net::HTTP)
      request = instance_double(Net::HTTP::Get)
      response = instance_double(Net::HTTPResponse)

      allow(Net::HTTP).to receive(:start).and_yield(http)
      allow(Net::HTTP::Get).to receive(:new).and_return(request)
      allow(http).to receive(:request).and_yield(response)
      allow(response).to receive(:read_body).and_yield('content')

      # Should not raise error even with wrong checksum
      expect do
        service.open(key, checksum: 'wrong_checksum') { |_f| nil }
      end.not_to raise_error
    end

    it 'cleans up tempfile after use' do
      http = instance_double(Net::HTTP)
      request = instance_double(Net::HTTP::Get)
      response = instance_double(Net::HTTPResponse)

      allow(Net::HTTP).to receive(:start).and_yield(http)
      allow(Net::HTTP::Get).to receive(:new).and_return(request)
      allow(http).to receive(:request).and_yield(response)
      allow(response).to receive(:read_body).and_yield('content')

      tempfile_path = nil
      service.open(key, checksum: checksum) do |tempfile|
        tempfile_path = tempfile.path
        expect(File.exist?(tempfile_path)).to be true
      end

      # Tempfile should be closed and deleted after block
      expect(File.exist?(tempfile_path)).to be false
    end

    it 'instruments the open operation' do
      http = instance_double(Net::HTTP)
      request = instance_double(Net::HTTP::Get)
      response = instance_double(Net::HTTPResponse)

      allow(Net::HTTP).to receive(:start).and_yield(http)
      allow(Net::HTTP::Get).to receive(:new).and_return(request)
      allow(http).to receive(:request).and_yield(response)
      allow(response).to receive(:read_body).and_yield('content')

      # The open method instruments both 'open' and 'streaming_download' (via download)
      expect(ActiveSupport::Notifications).to receive(:instrument).with(
        'service_open.active_storage',
        hash_including(key: key, checksum: checksum, service: :imagekit)
      ).and_call_original

      expect(ActiveSupport::Notifications).to receive(:instrument).with(
        'service_streaming_download.active_storage',
        hash_including(key: key, service: :imagekit)
      ).and_call_original

      service.open(key, checksum: checksum) { |_f| nil }
    end
  end

  describe '#download_chunk' do
    let(:key) { 'uploads/test/file.jpg' }
    let(:url) { 'https://ik.imagekit.io/test_account/uploads/test/file.jpg' }
    let(:range) { 0..1023 }

    before do
      allow(mock_helper).to receive(:build_url).and_return(url)
    end

    it 'downloads a byte range from the file' do
      http = instance_double(Net::HTTP)
      request = instance_double(Net::HTTP::Get)
      response = instance_double(Net::HTTPResponse, body: 'chunk content')

      allow(Net::HTTP).to receive(:start).and_yield(http)
      allow(Net::HTTP::Get).to receive(:new).and_return(request)
      allow(request).to receive(:[]=)
      allow(http).to receive(:request).and_return(response)

      result = service.download_chunk(key, range)
      expect(result).to eq('chunk content')
    end

    it 'sets the Range header correctly' do
      http = instance_double(Net::HTTP)
      request = instance_double(Net::HTTP::Get)
      response = instance_double(Net::HTTPResponse, body: 'chunk content')

      allow(Net::HTTP).to receive(:start).and_yield(http)
      allow(Net::HTTP::Get).to receive(:new).and_return(request)
      allow(http).to receive(:request).and_return(response)

      expect(request).to receive(:[]=).with('Range', 'bytes=0-1023')

      service.download_chunk(key, range)
    end

    it 'instruments the download_chunk' do
      http = instance_double(Net::HTTP)
      request = instance_double(Net::HTTP::Get)
      response = instance_double(Net::HTTPResponse, body: 'chunk content')

      allow(Net::HTTP).to receive(:start).and_yield(http)
      allow(Net::HTTP::Get).to receive(:new).and_return(request)
      allow(request).to receive(:[]=)
      allow(http).to receive(:request).and_return(response)

      expect(ActiveSupport::Notifications).to receive(:instrument).with(
        'service_download_chunk.active_storage',
        hash_including(key: key, range: range, service: :imagekit)
      ).and_call_original

      service.download_chunk(key, range)
    end
  end

  describe '#delete' do
    let(:key) { 'uploads/test/file.jpg' }

    it 'instruments the delete operation' do
      expect(ActiveSupport::Notifications).to receive(:instrument).with(
        'service_delete.active_storage',
        hash_including(key: key, service: :imagekit)
      ).and_call_original

      service.delete(key)
    end

    it 'does not raise an error (deletion not implemented)' do
      expect { service.delete(key) }.not_to raise_error
    end
  end

  describe '#delete_prefixed' do
    let(:prefix) { 'uploads/test/' }

    it 'instruments the delete_prefixed operation' do
      expect(ActiveSupport::Notifications).to receive(:instrument).with(
        'service_delete_prefixed.active_storage',
        hash_including(prefix: prefix, service: :imagekit)
      ).and_call_original

      service.delete_prefixed(prefix)
    end

    it 'does not raise an error (deletion not implemented)' do
      expect { service.delete_prefixed(prefix) }.not_to raise_error
    end
  end

  describe '#exist?' do
    let(:key) { 'uploads/test/file.jpg' }

    it 'returns true' do
      result = service.exist?(key)
      expect(result).to be true
    end

    it 'instruments the exist operation' do
      expect(ActiveSupport::Notifications).to receive(:instrument).with(
        'service_exist.active_storage',
        hash_including(key: key, service: :imagekit)
      ).and_call_original

      service.exist?(key)
    end

    it 'sets the exist payload' do
      payload = {}
      allow(ActiveSupport::Notifications).to receive(:instrument).and_yield(payload)

      service.exist?(key)

      expect(payload[:exist]).to be true
    end
  end

  describe '#url' do
    let(:key) { 'uploads/test/file.jpg' }
    let(:expected_url) { 'https://ik.imagekit.io/test_account/uploads/test/file.jpg' }

    before do
      allow(mock_helper).to receive(:build_url).and_return(expected_url)
    end

    it 'generates a URL for the file' do
      result = service.url(key)
      expect(result).to eq(expected_url)
    end

    it 'calls build_url with correct parameters' do
      expect(mock_helper).to receive(:build_url) do |src_options|
        expect(src_options).to be_a(Imagekit::Models::SrcOptions)
        expect(src_options.src).to eq(key)
        expect(src_options.url_endpoint).to eq('https://ik.imagekit.io/test_account')
        expect(src_options.transformation).to eq([])
        expected_url
      end

      service.url(key)
    end

    it 'generates a URL with transformations' do
      transformation = [{ width: 300, height: 200 }]

      expect(mock_helper).to receive(:build_url) do |src_options|
        # Check transformation is present and has the right structure
        expect(src_options.transformation).to be_an(Array)
        expect(src_options.transformation.length).to eq(1)
        expected_url
      end

      service.url(key, transformation: transformation)
    end

    it 'instruments the url operation' do
      expect(ActiveSupport::Notifications).to receive(:instrument).with(
        'service_url.active_storage',
        hash_including(key: key, service: :imagekit)
      ).and_call_original

      service.url(key)
    end

    it 'sets the url payload' do
      payload = {}
      allow(ActiveSupport::Notifications).to receive(:instrument).and_yield(payload)

      service.url(key)

      expect(payload[:url]).to eq(expected_url)
    end
  end

  describe 'integration with Active Storage service class' do
    it 'is a subclass of ActiveStorage::Service' do
      expect(described_class.superclass).to eq(ActiveStorage::Service)
    end

    it 'can be instantiated through ActiveStorage::Service::ImageKitService' do
      service = ActiveStorage::Service::ImageKitService.new(
        url_endpoint: 'https://ik.imagekit.io/test',
        public_key: 'test_public',
        private_key: 'test_private'
      )

      expect(service).to be_a(Imagekit::Rails::ActiveStorage::Service)
    end
  end

  describe 'private methods' do
    describe '#url_for_key' do
      let(:key) { 'uploads/test/file.jpg' }
      let(:expected_url) { 'https://ik.imagekit.io/test_account/uploads/test/file.jpg' }

      before do
        allow(mock_helper).to receive(:build_url).and_return(expected_url)
      end

      it 'builds URL without transformations' do
        result = service.send(:url_for_key, key)
        expect(result).to eq(expected_url)
      end

      it 'builds URL with transformations' do
        transformation = [{ width: 300 }]

        expect(mock_helper).to receive(:build_url) do |src_options|
          # Check transformation is present and has the right structure
          expect(src_options.transformation).to be_an(Array)
          expect(src_options.transformation.length).to eq(1)
          expected_url
        end

        service.send(:url_for_key, key, transformation: transformation)
      end
    end

    describe '#service_name' do
      it 'returns :imagekit' do
        expect(service.send(:service_name)).to eq(:imagekit)
      end
    end
  end
end
