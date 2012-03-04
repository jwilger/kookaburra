require 'kookaburra'

describe Kookaburra do
  describe '#given' do
    it 'returns an instance of the configured GivenDriver' do
      my_given_driver_class = Class.new do
        def initialize(*args); end
      end
      my_api_driver_class = Class.new do
        def initialize(*args); end
      end
      browser_instance = stub('Browser', :app => :a_rack_app)
      k = Kookaburra.new(:given_driver_class => my_given_driver_class,
                         :api_driver_class => my_api_driver_class,
                         :browser => browser_instance)
      k.given.should be_kind_of(my_given_driver_class)
    end
  end

  describe '#ui' do
    it 'returns an instance of the configured UIDriver' do
      my_ui_driver_class = Class.new do
        def initialize(*args); end
      end
      k = Kookaburra.new(:ui_driver_class => my_ui_driver_class, :browser => :a_browser)
      k.ui.should be_kind_of(my_ui_driver_class)
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
end
