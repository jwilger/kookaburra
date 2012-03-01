require 'kookaburra/ui_driver/ui_component'
require 'support/shared_examples/browser_injection'

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
        lambda { component.send(:component_path) } \
          .should raise_error(Kookaburra::ConfigurationError)
      end
    end

    it_behaves_like :browser_injection do
      let(:subject_class) { Kookaburra::UIDriver::UIComponent }
    end
  end
end
