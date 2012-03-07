require 'kookaburra/ui_driver/ui_component'
require 'support/shared_examples/it_has_a_dependency_accessor'

describe Kookaburra::UIDriver::UIComponent do
  describe '#visible?' do
    it 'passes the browser object to the server error detection function' do
      browser = stub('Browser', :has_css? => true)
      server_error_detection = lambda { |b|
        b.should === browser
        false
      }
      component = Kookaburra::UIDriver::UIComponent.new(
        :browser => browser,
        :server_error_detection => server_error_detection)
      component.stub!(:component_locator => '#my_component')
      component.visible?
    end

    shared_examples_for :server_error_detection_passed do
      it 'returns true if the component_locator is found on the page' do
        browser = mock('Browser')
        browser.should_receive(:has_css?).with('#my_component').and_return(true)
        component = Kookaburra::UIDriver::UIComponent.new(
          :browser => browser,
          :server_error_detection => server_error_detection)
        component.stub!(:component_locator => '#my_component')
        component.visible?.should == true
      end

      it 'returns false if the component_locator is not found on the page' do
        browser = mock('Browser')
        browser.should_receive(:has_css?).with('#my_component').and_return(false)
        component = Kookaburra::UIDriver::UIComponent.new(
          :browser => browser,
          :server_error_detection => server_error_detection)
        component.stub!(:component_locator => '#my_component')
        component.visible?.should == false
      end
    end

    context 'no server error detection function is specified' do
      let(:server_error_detection) { nil }
      it_behaves_like :server_error_detection_passed
    end

    context 'no server error is detected' do
      let(:server_error_detection) do
        lambda { |b| false }
      end

      it_behaves_like :server_error_detection_passed
    end

    context 'a server error is detected' do
      it 'raises a Kookaburra::UnexpectedResponse exception' do
        server_error_detection = lambda { |b| true }
        browser = stub('Browser')
        component = Kookaburra::UIDriver::UIComponent.new(
          :browser => browser,
          :server_error_detection => server_error_detection)
        lambda { component.visible? } \
          .should raise_error(Kookaburra::UnexpectedResponse, "Your server error detection function detected a server error. Looks like your applications is busted. :-(")
      end
    end
  end

  describe '#show' do
    context 'the component is not currently visible' do
      it 'causes the browser to navigate to the value of #component_path' do
        browser = mock('Browser Session')
        browser.should_receive(:visit).with('/foo')
        component = Kookaburra::UIDriver::UIComponent.new(:browser => browser)
        component.stub!(:component_path => '/foo', :visible? => false)
        component.show
      end

      it 'passes any arguments to the #component_path for processing' do
        browser = mock('Browser Session', :visit => nil)
        component = Kookaburra::UIDriver::UIComponent.new(:browser => browser)
        component.should_receive(:component_path).with(:foo => :bar, :baz => :bam)
        component.stub!(:visible? => false)
        component.show(:foo => :bar, :baz => :bam)
      end
    end

    context 'the component is already visible' do
      it 'does not navigate to #component path' do
        browser = mock('Browser Session')
        browser.should_receive(:visit).never
        component = Kookaburra::UIDriver::UIComponent.new(:browser => browser)
        component.stub!(:component_path => '/foo', :visible? => true)
        component.show
      end
    end
  end

  describe 'private methods (for use by subclasses)' do
    describe '#component_path' do
      it 'must be defined by subclasses' do
        component = Kookaburra::UIDriver::UIComponent.new
        lambda { component.send(:component_path) } \
          .should raise_error(Kookaburra::ConfigurationError)
      end
    end

    describe '#component_locator' do
      it 'must be defined by subclasses' do
        component = Kookaburra::UIDriver::UIComponent.new
        lambda { component.send(:component_locator) } \
          .should raise_error(Kookaburra::ConfigurationError)
      end
    end

    it_behaves_like :it_has_a_dependency_accessor, :browser do
      let(:subject_class) { Kookaburra::UIDriver::UIComponent }
    end
  end
end
