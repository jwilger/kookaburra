require 'kookaburra/test_helpers'

describe Kookaburra::TestHelpers do
  let(:includer) do
    klass = Class.new do
      include Kookaburra::TestHelpers
    end
    klass.new
  end

  before(:each) do
    Kookaburra.stub!(:configuration => {
      :api_driver_class => :my_api_driver,
      :given_driver_class => :my_given_driver,
      :ui_driver_class => :my_ui_driver,
      :browser => :a_browser_object,
      :server_error_detection => :my_server_error_detection
    })
  end

  describe '#k' do
    it 'returns a configured instance of Kookaburra' do
      Kookaburra.should_receive(:new) \
        .with(Kookaburra.configuration) \
        .and_return(:a_kookaburra_object)
      includer.k.should == :a_kookaburra_object
    end

    it 'memoizes the return value' do
      Kookaburra.should_receive(:new).once.and_return(Object.new)
      includer.k.should === includer.k
    end
  end

  describe '#given' do
    it 'returns the GivenDriver from the Kookaburra instance' do
      Kookaburra.stub!(:new => stub('Kookaburra', :given => :given_driver_instance))
      includer.given.should == :given_driver_instance
    end
  end

  describe '#ui' do
    it 'returns the UIDriver from the Kookaburra instance' do
      Kookaburra.stub!(:new => stub('Kookaburra', :ui => :ui_driver_instance))
      includer.ui.should == :ui_driver_instance
    end
  end
end
