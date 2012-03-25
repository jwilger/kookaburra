require 'kookaburra/ui_driver/ui_component'

describe Kookaburra::UIDriver::UIComponent do
  describe '#show' do
    context 'the component is not currently visible' do
      it 'causes the browser to navigate to the value of #component_path' do
        browser = mock('Browser Session')
        browser.should_receive(:visit).with('/foo')
        component = Kookaburra::UIDriver::UIComponent.new(:browser => browser)
        component.stub!(:component_path => '/foo')
        component.stub!(:visible?).and_return(false, true)
        component.show
      end

      it 'passes any arguments to the #component_path for processing' do
        browser = mock('Browser Session', :visit => nil)
        component = Kookaburra::UIDriver::UIComponent.new(:browser => browser)
        component.should_receive(:component_path).with(:foo => :bar, :baz => :bam)
        component.stub!(:visible?).and_return(false, true)
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

  describe '#respond_to?' do
    let(:component_class) do
      Class.new(Kookaburra::UIDriver::UIComponent) do
        def foo
        end
      end
    end

    it 'returns true if the UIComponent defines the specified method' do
      component = component_class.new
      component.respond_to?(:foo).should == true
    end

    it 'returns true if the #browser defines the specified method' do
      browser = stub('Browser Driver', :respond_to? => true)
      component = component_class.new
      component.stub!(:browser => browser)
      component.respond_to?(:a_very_unlikely_method_name).should == true
    end

    it 'returns false if neither the UIComponent nor the #browser define the specified method' do
      browser = stub('Browser Driver', :respond_to? => false)
      component = component_class.new
      component.stub!(:browser => browser)
      component.respond_to?(:a_very_unlikely_method_name).should == false
    end
  end

  describe '#method_missing' do
    context 'the component says it responds to the method' do
      it 'scopes the method call within the component_locator and forwards to #browser' do
        browser = mock('Browser Driver')
        browser.should_receive(:some_browser_method) \
          .with(:arguments) \
          .and_return(:answer_from_browser)
        browser.should_receive(:within) do |scope, &block|
          scope.should == '#my_component'
          block.call(browser)
        end
        component = Kookaburra::UIDriver::UIComponent.new(:browser => browser)
        component.stub!(:component_locator => '#my_component')
        component.some_browser_method(:arguments).should == :answer_from_browser
      end
    end

    context 'the component says it does not respond to the method' do
      it 'raises a NoMethodError' do
        component = Kookaburra::UIDriver::UIComponent.new
        component.stub!(:respond_to? => false)
        lambda { component.no_such_method } \
          .should raise_error(NoMethodError)
      end
    end
  end

  describe '#visible?' do
    it 'returns true if the component_locator is found in the DOM and is visible' do
      browser = mock('Browser Driver')
      browser.should_receive(:has_css?) \
        .with('#my_component', :visible) \
        .and_return(true)
      component = Kookaburra::UIDriver::UIComponent.new(:browser => browser)
      component.stub!(:component_locator => '#my_component')
      component.visible?.should == true
    end

    it 'returns false if the component_locator id not found in the DOM' do
      browser = stub('Browser Driver', :has_css? => false)
      component = Kookaburra::UIDriver::UIComponent.new(
        :browser => browser,
        :server_error_detection => lambda { |browser|
          false
        }
      )
      component.stub!(:component_locator => '#my_component')
      component.visible?.should == false
    end

    it 'raises UnexpectedResponse if the component_locator is not found and a server error is detected' do
      browser = stub('Browser Driver', :has_css? => false)
      component = Kookaburra::UIDriver::UIComponent.new(
        :browser => browser,
        :server_error_detection => lambda { |browser|
          true
        }
      )
      component.stub!(:component_locator => '#my_component')
      lambda { component.visible? } \
        .should raise_error(Kookaburra::UnexpectedResponse)
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

    describe '#assert' do
      it 'returns true if the condition is truthy' do
        component = Kookaburra::UIDriver::UIComponent.new
        component.send(:assert, true, "Shouldn't see this message").should == true
      end

      it 'raises a Kookaburra::AssertionFailed exception if the condition is not truthy' do
        component = Kookaburra::UIDriver::UIComponent.new
        lambda { component.send(:assert, false, "False isn't true, dummy.") } \
          .should raise_error(Kookaburra::AssertionFailed, "False isn't true, dummy.")
      end
    end
  end
end
