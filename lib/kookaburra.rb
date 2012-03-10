require 'kookaburra/exceptions'
require 'kookaburra/test_data'
require 'kookaburra/given_driver'
require 'kookaburra/ui_driver'

# Kookaburra provides the top-level API that you will access in your test
# implementation, namely the {#given}, {#ui}, and the {#get_data} methods.
#
# The Kookaburra object ensures that your GivenDriver and UIDriver share the
# same state with regard to any fixture data that is created during your test
# run. As such, it is important to ensure that a new instance of Kookaburra is
# created for each individual test, otherwise you may wind up with test state
# bleeding over from one test to the next. The {Kookaburra::TestHelpers} module
# is intended to be mixed in to your testing context for this purpose.
#
# @see Kookaburra::TestHelpers
class Kookaburra
  class << self
    # {Kookaburra::TestHelpers#k} uses the value stored here as the options
    # argument to {Kookaburra#initialize}. See {Kookaburra#initialize} for the
    # list of valid keys and their contents.
    attr_accessor :configuration
  end

  # Returns a new Kookaburra instance that wires together your application's
  # APIDriver, GivenDriver, and UIDriver.
  #
  # @option options [Kookaburra::APIDriver] :api_driver_class Your application's
  #   subclass of {Kookaburra::APIDriver}. At the moment, only the
  #   {Kookaburra::JsonApiDriver} is implemented
  # @option options [Kookaburra::GivenDriver] :given_driver_class Your
  #   application's subclass of {Kookaburra::GivenDriver}
  # @option options [Kookaburra::UIDriver] :ui_driver_class Your application's
  #   subclass of {Kookaburra::UIDriver}
  # @option options [Capybara::Session] :browser The browser driver that
  #   Kookaburra will interact with to run the tests. It must also respond to
  #   the #app method and return a Rack application for use with the
  #   {Kookaburra::APIDriver}.
  def initialize(options = {})
    @api_driver_class   = options[:api_driver_class]
    @given_driver_class = options[:given_driver_class]
    @ui_driver_class    = options[:ui_driver_class]
    @browser            = options[:browser]
    @server_error_detection = options[:server_error_detection]
  end

  # Returns an instance of your GivenDriver class configured to share test
  # fixture data with the UIDriver and to use your APIDriver class to
  # communicate with your application
  def given
    given_driver_class.new(:test_data => test_data, :api => api)
  end

  # Returns an instance of your UIDriver class configured to share test fixture
  # data with the GivenDriver and to use the browser driver you specified in
  # {#initialize}
  def ui
    ui_driver_class.new(:test_data => test_data, :browser => browser, :server_error_detection => @server_error_detection)
  end

  # Returns a frozen copy of the specified test fixture data collection.
  # However, this is neither a deep copy nor a deep freeze, so it is possible
  # that you could modify data outside of your GivenDriver or UIDriver. Just
  # don't do that. Trust me.
  #
  # This access is provided so that you can reference the current fixture data
  # within your test implementation in order to make assertions about the state
  # of your application's interface.
  #
  # @example
  #   given.a_widget(:foo)
  #   ui.create_a_new_widget(:bar)
  #   ui.widget_list.widgets.should == k.get_data(:widgets).slice(:foo, :bar)
  def get_data(collection_name)
    test_data.send(collection_name).dup.freeze
  end

  private

  extend DependencyAccessor
  dependency_accessor :given_driver_class, :api_driver_class, :ui_driver_class, :browser

  def api
    api_driver_class.new(RackDriver.new(browser.app))
  end

  def test_data
    @test_data ||= TestData.new
  end

end
