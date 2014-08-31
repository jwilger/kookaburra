require 'spec_helper'
require 'kookaburra'

describe Kookaburra do
  let(:configuration) {
    double('configuration', :mental_model= => nil,
           ui_driver_class: nil,
           api_driver_class: nil)
  }

  let(:k) { Kookaburra.new(configuration) }

  describe '#api' do
    it 'returns an instance of the configured APIDriver' do
      my_api_driver_class = double(Class)
      expect(my_api_driver_class).to receive(:new) \
        .with(configuration) \
        .and_return(:an_api_driver)
      allow(configuration).to receive(:api_driver_class) { my_api_driver_class }
      expect(k.api).to eq :an_api_driver
    end
  end

  describe '#ui' do
    it 'returns an instance of the configured UIDriver' do
      my_ui_driver_class = double(Class)
      expect(my_ui_driver_class).to receive(:new) \
        .with(configuration) \
        .and_return(:a_ui_driver)
      allow(configuration).to receive(:ui_driver_class) { my_ui_driver_class }
      expect(k.ui).to eq :a_ui_driver
    end
  end

  describe '#get_data' do
    it 'returns a dup of the specified MentalModel::Collection' do
      collection = double('MentalModel::Collection')
      expect(collection).to receive(:dup) \
        .and_return(:mental_model_collection_dup)
      allow(configuration).to receive(:mental_model) {
        double(:foos => collection)
      }
      expect(k.get_data(:foos)).to eq :mental_model_collection_dup
    end
  end

  describe '.configuration' do
    it 'returns a Kookaburra::Configuration instance' do
      expect(Kookaburra.configuration).to be_kind_of(Kookaburra::Configuration)
    end

    it 'always returns the same configuration' do
      x = Kookaburra.configuration
      y = Kookaburra.configuration
      x.app_host = 'http://example.com'
      expect(y.app_host).to eq 'http://example.com'
    end
  end

  describe '.configure' do
    it 'yields Kookaburra.configuration' do
      configuration = double('Kookaburra::Configuration')
      expect(configuration).to receive(:foo=).with(:bar)
      allow(Kookaburra).to receive(:configuration) { configuration }
      Kookaburra.configure do |c|
        c.foo = :bar
      end
    end
  end
end
