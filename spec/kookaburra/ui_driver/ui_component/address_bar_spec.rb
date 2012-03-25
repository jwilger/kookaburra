require 'kookaburra/ui_driver/ui_component/address_bar'

describe Kookaburra::UIDriver::UIComponent::AddressBar do
  describe '#go_to' do
    let(:browser) {
      mock('Capybara::Session').tap do |b|
        b.should_receive(:visit).with('http://site.example.com')
      end
    }

    let(:configuration) {
      stub('Configuration', :browser => browser, :app_host => nil, :server_error_detection => nil)
    }

    let(:address_bar) {
      address_bar = Kookaburra::UIDriver::UIComponent::AddressBar.new(configuration)
    }

    context 'when given a string' do
      it 'causes the browser to navigate to the (presumably URL) string' do
        address_bar.go_to 'http://site.example.com'
      end
    end

    context 'when given a string' do
      it 'causes the browser to navigate to the (presumably URL) string' do
        addressable = stub('addressable', :url => 'http://site.example.com')
        address_bar.go_to addressable
      end
    end
  end
end
