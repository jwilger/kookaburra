require 'spec_helper'
require 'kookaburra/ui_driver/ui_component'
require 'support/shared_examples/it_can_make_assertions'
require 'support/shared_examples/it_can_have_ui_components'

describe Kookaburra::UIDriver::UIComponent do
  let(:browser) { double('Browser Driver') }
  let(:app_host) { 'http://my.example.com' }
  let(:server_error_detection) { ->(browser) { false } }

  let(:configuration) {
    double('Configuration', browser: browser, app_host: app_host,
           server_error_detection: server_error_detection)
  }

  let(:component) { Kookaburra::UIDriver::UIComponent.new(configuration) }

  it_behaves_like :it_can_have_ui_components, Kookaburra::UIDriver::UIComponent

  describe '#visible?' do
    before(:each) do
      def component.component_locator
        '#my_component'
      end
    end

    it 'returns true if the component_locator is found in the DOM and is visible' do
      expect(browser).to receive(:has_css?) \
        .with('#my_component', visible: true) \
        .and_return(true)
      expect(component).to be_visible
    end

    context 'when the component_locator is not found in the DOM' do
      let(:browser) { double('Browser Driver', has_css?: false, text: '') }

      context 'and a server error is not detected' do
        it 'returns false' do
          expect(component).to_not be_visible
        end
      end

      context 'and a server error is detected' do
        let(:server_error_detection) { ->(browser) { true } }

        it 'raises UnexpectedResponse' do
          expect{ component.visible? }.to \
            raise_error(Kookaburra::UnexpectedResponse)
        end

        it 'adds the text of the HTTP response to the exception message' do
          allow(browser).to receive(:text) {
            'This is text from the HTTP response'
          }

          expect{ component.visible? }.to \
            raise_error(Kookaburra::UnexpectedResponse,
                        "Server Error Detected:\n" \
                        + "This is text from the HTTP response")
        end
      end
    end
  end

  describe '#not_visible?' do
    before(:each) do
      def component.component_locator
        '#my_component'
      end
    end

    it 'returns true if the component_locator is not found in the DOM or is not visible' do
      expect(browser).to receive(:has_no_css?) \
        .with('#my_component', visible: true) \
        .and_return(true)
      expect(component).to be_not_visible
    end

    it 'returns false if the component_locator is found in the DOM and is visible' do
      expect(browser).to receive(:has_no_css?) \
        .with('#my_component', visible: true) \
        .and_return(false)
      expect(component).to_not be_not_visible
    end

    context 'when the component_locator is found in the DOM' do
      let(:browser) { double('Browser Driver', has_css?: false, text: '') }

      it 'returns false' do
        expect(component).to_not be_visible
      end
    end
  end

  describe '#url' do
    it 'returns the app_host + #component_path' do
      def component.component_path
        '/foo/bar'
      end
      expect(component.url).to eq 'http://my.example.com/foo/bar'
    end
  end

  describe 'protected methods (for use by subclasses)' do
    describe '#component_path' do
      it 'must be defined by subclasses' do
        expect{ component.send(:component_path) }.to \
          raise_error(Kookaburra::ConfigurationError)
      end
    end

    describe '#component_locator' do
      it 'defaults to a string based on the class name' do
        expected = "#" + component.class.name.gsub(/::/, '/').
          gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').
          tr("-", "_").
          gsub('/', '-').
          downcase
        expect(component.send(:component_locator)).to eq expected
      end
    end

    describe '#this_element' do
      it 'returns the HTML element representing this component' do
        element = double('Element')

        def component.component_locator
          '#my_component'
        end

        expect(browser).to receive(:find).with('#my_component').and_return(element)
        expect(component.send(:this_element)).to be(element)
      end
    end

    it_behaves_like :it_can_make_assertions do
      let(:subject) { component }
    end
  end
end
