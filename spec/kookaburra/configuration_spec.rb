require 'spec_helper'
require 'kookaburra/configuration'
require 'support/shared_examples/it_has_a_dependency_accessor'

describe Kookaburra::Configuration do
  it_behaves_like :it_has_a_dependency_accessor, :api_driver_class
  it_behaves_like :it_has_a_dependency_accessor, :ui_driver_class
  it_behaves_like :it_has_a_dependency_accessor, :browser
  it_behaves_like :it_has_a_dependency_accessor, :app_host
  it_behaves_like :it_has_a_dependency_accessor, :logger

  describe '#server_error_detection' do
    it 'returns the block that it was last given' do
      block = lambda { 'foo' }
      subject.server_error_detection(&block)
      expect(subject.server_error_detection).to eq block
    end
  end

  describe '#app_host_uri' do
    it 'returns a URI version of the #app_host attribute via URI.parse' do
      expect(URI).to receive(:parse) \
        .with('http://example.com') \
        .and_return(:a_parsed_uri)
      subject.app_host = 'http://example.com'
      expect(subject.app_host_uri).to eq :a_parsed_uri
    end

    it 'changes if #app_host changes' do
      allow(URI).to receive(:parse) do |url|
        url.to_sym
      end
      subject.app_host = 'http://example.com'
      expect(subject.app_host_uri).to eq 'http://example.com'.to_sym
      subject.app_host = 'http://foo.example.com'
      expect(subject.app_host_uri).to eq 'http://foo.example.com'.to_sym
    end
  end

  describe '#mental_model' do
    it 'returns an instance of MentalModel' do
      expect(subject.mental_model).to be_kind_of Kookaburra::MentalModel
    end

    it 'always returns the same instance' do
      expect(subject.mental_model.__id__).to eq subject.mental_model.__id__
    end
  end

  describe '#application' do
    let(:proxy) { double(:proxy) }
    let(:app_kookaburra) { double(:app_kookaburra) }

    before(:each) do
      allow(Kookaburra::Configuration::Proxy).to receive(:new) { proxy }
      allow(Kookaburra).to receive(:new) { app_kookaburra }
    end

    it 'builds a proxy configuration based on this one' do
      expect(Kookaburra::Configuration::Proxy).to receive(:new) \
        .with(name: :foo, basis: subject)
      subject.application(:foo)
    end

    it 'yields the proxy configuration' do
      expect{ |b| subject.application(:foo, &b) }.to yield_with_args(proxy)
    end

    it 'builds a new Kookaburra instance with the proxy configuration' do
      expect(Kookaburra).to receive(:new).with(proxy)
      subject.application(:foo)
    end

    it 'stores the new Kookaburra instance by name' do
      expect(subject.applications.keys).to_not include(:foo)
      subject.application(:foo)
      expect(subject.applications[:foo]).to equal app_kookaburra
    end
  end
end
