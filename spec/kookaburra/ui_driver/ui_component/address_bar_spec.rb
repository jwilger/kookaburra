require 'spec_helper'
require 'kookaburra/ui_driver/ui_component/address_bar'

describe Kookaburra::UIDriver::UIComponent::AddressBar do
  describe '#go_to' do
    let(:browser) {
      double('Capybara::Session', text: '').tap do |b|
        allow(b).to receive(:visit).with('http://site.example.com')
      end
    }

    let(:error_detector) { nil }

    let(:configuration) {
      double('Configuration', :browser => browser, :app_host => nil, :server_error_detection => error_detector)
    }

    let(:address_bar) {
      address_bar = Kookaburra::UIDriver::UIComponent::AddressBar.new(configuration)
    }

    context 'when given a string' do
      it 'causes the browser to navigate to the (presumably URL) string' do
        address_bar.go_to 'http://site.example.com'
      end
    end

    context 'when given an addressable object' do
      it "causes the browser to navigate to the object's #url" do
        addressable = double('addressable', :url => 'http://site.example.com')
        address_bar.go_to addressable
      end
    end

    context "when a server error would be detected" do
      let(:error_detector) { ->(browser) { true } }

      it 'raises a Kookaburra::UnexpectedResponse' do
        expect { address_bar.go_to 'http://site.example.com' } \
          .to raise_error(Kookaburra::UnexpectedResponse)
      end
    end
  end
end
