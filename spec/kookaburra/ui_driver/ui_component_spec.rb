require 'kookaburra/ui_driver/ui_component'
require 'support/shared_examples/it_has_a_dependency_accessor'

describe Kookaburra::UIDriver::UIComponent do
  describe '#show' do
    context 'the component is not currently visible' do
      it 'causes the browser to navigate to the value of #component_path' do
        browser = mock('Browser Session')
        browser.should_receive(:visit).with('/foo')
        component = Kookaburra::UIDriver::UIComponent.new(:browser => browser)
        component.stub!(:component_path => '/foo', :visible? => false, :assert_visible => true)
        component.show
      end

      it 'passes any arguments to the #component_path for processing' do
        browser = mock('Browser Session', :visit => nil)
        component = Kookaburra::UIDriver::UIComponent.new(:browser => browser)
        component.should_receive(:component_path).with(:foo => :bar, :baz => :bam)
        component.stub!(:visible? => false, :assert_visible => true)
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

    it 'returns true if the #element defines the specified method' do
      element = stub('An Element', :respond_to? => true)
      component = component_class.new
      component.stub!(:element => element)
      component.respond_to?(:a_very_unlikely_method_name).should == true
    end

    it 'returns false if neither the UIComponent nor the #element define the specified method' do
      element = stub('An Element', :respond_to? => false)
      component = component_class.new
      component.stub!(:element => element)
      component.respond_to?(:a_very_unlikely_method_name).should == false
    end
  end

  describe '#method_missing' do
    it 'forwards method calls to #element' do
      element = mock('An Element')
      element.should_receive(:some_method) do |arg1, arg2, &block|
        arg1.should == :a
        arg2.should == :b
        block.call.should == :c
        :d
      end
      component = Kookaburra::UIDriver::UIComponent.new
      component.stub!(:element => element)
      result = component.some_method(:a, :b) do
        :c
      end
      result.should == :d
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

    it_behaves_like :it_has_a_dependency_accessor, :browser do
      let(:subject_class) { Kookaburra::UIDriver::UIComponent }
    end

    describe '#element' do
      it 'passes the browser object to the server error detection function' do
        browser = stub('Browser', :find => :an_element)
        server_error_detection = lambda { |b|
          b.should === browser
          false
        }
        component = Kookaburra::UIDriver::UIComponent.new(:browser => browser,
                                                          :server_error_detection => server_error_detection)
        component.stub!(:component_locator => '#my_component')
        component.send(:element)
      end

      shared_examples_for :server_error_detection_passed do
        it 'returns the element node if the component_locator is found on the page' do
          browser = mock('Browser')
          browser.should_receive(:find).with('#my_component').and_return(:the_element_node)
          component = Kookaburra::UIDriver::UIComponent.new(
            :browser => browser,
            :server_error_detection => server_error_detection)
          component.stub!(:component_locator => '#my_component')
          component.send(:element).should == :the_element_node
        end

        it 'raises Kookaburra::ComponentNotFound if the component_locator is not found on the page' do
          browser = mock('Browser')
          browser.should_receive(:find).with('#my_component').and_raise(StandardError)
          component = Kookaburra::UIDriver::UIComponent.new(
            :browser => browser,
            :server_error_detection => server_error_detection)
          component.stub!(:component_locator => '#my_component')
          lambda { component.send(:element) } \
            .should raise_error(Kookaburra::ComponentNotFound)
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
          lambda { component.send(:element) } \
            .should raise_error(Kookaburra::UnexpectedResponse, "Your server error detection function detected a server error. Looks like your applications is busted. :-(")
        end
      end
    end
  end
end
