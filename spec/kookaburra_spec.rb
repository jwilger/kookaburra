require 'kookaburra'

describe Kookaburra do
  describe '#given' do
    it 'returns an instance of the configured GivenDriver' do
      browser_instance = stub('Browser', :app => :a_rack_app)

      Kookaburra::RackDriver.should_receive(:new) \
        .with(:a_rack_app) \
        .and_return(:a_rack_driver)

      my_api_driver_class = mock(Class)
      my_api_driver_class.should_receive(:new) \
        .with(:a_rack_driver) \
        .and_return(:an_api_driver)

      my_given_driver_class = mock(Class)
      my_given_driver_class.should_receive(:new) do |options|
        options[:api].should == :an_api_driver
        :a_given_driver
      end

      k = Kookaburra.new(:given_driver_class => my_given_driver_class,
                         :api_driver_class => my_api_driver_class,
                         :browser => browser_instance)
      k.given.should == :a_given_driver
    end
  end

  describe '#ui' do
    it 'returns an instance of the configured UIDriver' do
      my_ui_driver_class = mock(Class)
      my_ui_driver_class.should_receive(:new) do |options|
        options[:browser].should == :a_browser
        options[:server_error_detection].should == :server_error_detection
        :a_ui_driver
      end
      k = Kookaburra.new(:ui_driver_class => my_ui_driver_class,
                         :browser => :a_browser,
                         :server_error_detection => :server_error_detection)
      k.ui.should == :a_ui_driver
    end
  end

  describe '#get_data' do
    it 'returns a equivalent copy of the test data collection specified' do
      k = Kookaburra.new
      foos = {:spam => 'ham'}
      test_data = stub(:foos => foos)
      k.stub!(:test_data => test_data)
      k.get_data(:foos).should == foos
    end

    it 'does not return the same object that is the test data collection' do
      k = Kookaburra.new
      k.get_data(:foos).should_not === k.get_data(:foos)
    end

    it 'returns a frozen object' do
      k = Kookaburra.new
      k.get_data(:foos).should be_frozen
    end
  end

  describe '.configuration' do
    it 'returns the assigned value' do
      begin
        old_config = Kookaburra.configuration
        Kookaburra.configuration = :test_configuration
        Kookaburra.configuration.should == :test_configuration
      ensure
        Kookaburra.configuration = old_config
      end
    end

    it 'defaults to an empty hash' do
      Kookaburra.configuration.should == {}
    end
  end
end
