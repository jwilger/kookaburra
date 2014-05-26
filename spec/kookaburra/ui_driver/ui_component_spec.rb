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
      browser.should_receive(:has_css?) \
        .with('#my_component', :visible) \
        .and_return(true)
      component.visible?.should == true
    end

    context 'when the component_locator is not found in the DOM' do
      let(:browser) { double('Browser Driver', has_css?: false, text: '') }

      context 'and a server error is not detected' do
        it 'returns false' do
          component.visible?.should == false
        end
      end

      context 'and a server error is detected' do
        let(:server_error_detection) { ->(browser) { true } }

        it 'raises UnexpectedResponse' do
          lambda { component.visible? } \
            .should raise_error(Kookaburra::UnexpectedResponse)
        end

        it 'adds the text of the HTTP response to the exception message' do
          browser.stub(text: 'This is text from the HTTP response')
          lambda { component.visible? } \
            .should raise_error(Kookaburra::UnexpectedResponse,
                                "Server Error Detected:\n" \
                                + "This is text from the HTTP response")
        end
      end
    end
  end

  describe '#url' do
    it 'returns the app_host + #component_path' do
      def component.component_path
        '/foo/bar'
      end
      component.url.should == 'http://my.example.com/foo/bar'
    end
  end

  describe 'protected methods (for use by subclasses)' do
    describe '#component_path' do
      it 'must be defined by subclasses' do
        lambda { component.send(:component_path) } \
          .should raise_error(Kookaburra::ConfigurationError)
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
