require 'kookaburra/ui_driver/ui_component'

describe Kookaburra::UIDriver::UIComponent do
  describe '#show' do
    it 'causes the browser to navigate to the value of #component_path' do
      browser = mock('Browser Session')
      browser.should_receive(:visit).with('/foo')
      component = Kookaburra::UIDriver::UIComponent.new(:browser => browser)
      component.stub!(:component_path => '/foo')
      component.show
    end

    it 'passes any arguments to the #component_path for processing' do
      browser = mock('Browser Session', :visit => nil)
      component = Kookaburra::UIDriver::UIComponent.new(:browser => browser)
      component.should_receive(:component_path).with(:foo => :bar, :baz => :bam)
      component.show(:foo => :bar, :baz => :bam)
    end
  end

  describe 'private methods (for use by subclasses)' do
    describe '#component_path' do
      it 'raises a Kookaburra::ConfigurationError' do
        component = Kookaburra::UIDriver::UIComponent.new
        component.stub!(:class_name => 'Foo::Bar')
        lambda { component.send(:component_path) } \
          .should raise_error(Kookaburra::ConfigurationError)
      end

      it 'explains that it must be implemented by subclasses' do
        component = Kookaburra::UIDriver::UIComponent.new
        component.stub!(:class_name => 'Foo::Bar')
        begin
          component.send(:component_path)
        rescue Kookaburra::ConfigurationError => e
          e.message.should == 'You must define Foo::Bar#component_path.'
        end
      end
    end

    describe '#class_name' do
      it 'returns the name of the subclass of the UIComponent' do
        component_class = Class.new(Kookaburra::UIDriver::UIComponent)
        component_class.stub!(:name => 'Bar::Baz')
        component = component_class.new
        component.send(:class_name).should == 'Bar::Baz'
      end
    end

    describe '#browser' do
      it 'returns the browser object passed in at initialization' do
        browser = Object.new
        component = Kookaburra::UIDriver::UIComponent.new(:browser => browser)
        component.send(:browser).should === browser
      end

      context 'when the browser object is not set' do
        it 'raises a StandardError' do
          component = Kookaburra::UIDriver::UIComponent.new
          lambda { component.send(:browser) } \
            .should raise_error(StandardError)
        end

        it 'explains that the browser was not set by the UIDriver' do
          component = Kookaburra::UIDriver::UIComponent.new
          component.stub!(:class_name => 'Foo')
          begin
            component.send(:browser)
          rescue StandardError => e
            e.message.should == 'No browser object was set on Foo initialization.'
          end
        end
      end
    end
  end
end
