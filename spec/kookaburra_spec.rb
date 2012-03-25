require 'kookaburra'

describe Kookaburra do
  let(:configuration) {
    OpenStruct.new
  }

  let(:k) { Kookaburra.new(configuration) }

  describe '#given' do
    it 'returns an instance of the configured GivenDriver' do
      my_given_driver_class = mock(Class)
      my_given_driver_class.should_receive(:new) \
        .with(configuration) \
        .and_return(:a_given_driver)
      configuration.stub!(:given_driver_class => my_given_driver_class)
      k.given.should == :a_given_driver
    end
  end

  describe '#ui' do
    it 'returns an instance of the configured UIDriver' do
      my_ui_driver_class = mock(Class)
      my_ui_driver_class.should_receive(:new) \
        .with(configuration) \
        .and_return(:a_ui_driver)
      configuration.stub!(:ui_driver_class => my_ui_driver_class)
      k.ui.should == :a_ui_driver
    end
  end

  describe '#get_data' do
    it 'returns a equivalent copy of the test data collection specified' do
      foos = {:spam => 'ham'}
      configuration.stub!(:mental_model => stub(:foos => foos))
      k.get_data(:foos).should == foos
    end

    it 'does not return the same object that is the test data collection' do
      k.get_data(:foos).should_not === k.get_data(:foos)
    end

    it 'returns a frozen object' do
      k.get_data(:foos).should be_frozen
    end
  end

  describe '.configuration' do
    it 'returns a Kookaburra::Configuration instance' do
      Kookaburra.configuration.should be_kind_of(Kookaburra::Configuration)
    end

    it 'always returns the same configuration' do
      x = Kookaburra.configuration
      y = Kookaburra.configuration
      x.app_host = 'http://example.com'
      y.app_host.should == 'http://example.com'
    end
  end

  describe '.configure' do
    it 'yields Kookaburra.configuration' do
      configuration = mock('Kookaburra::Configuration')
      configuration.should_receive(:foo=).with(:bar)
      Kookaburra.stub!(:configuration => configuration)
      Kookaburra.configure do |c|
        c.foo = :bar
      end
    end
  end
end
