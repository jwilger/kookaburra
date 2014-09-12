require 'forwardable'
require 'kookaburra/exceptions'
require 'kookaburra/mental_model'
require 'kookaburra/api_driver'
require 'kookaburra/ui_driver'
require 'kookaburra/configuration'

# Kookaburra provides the top-level API that you will access in your test
# implementation, namely the {#api}, {#ui}, and the {#get_data} methods.
#
# The Kookaburra object ensures that your APIDriver and UIDriver share the
# same state with regard to any {Kookaburra::MentalModel} data that is created
# during your test run. As such, it is important to ensure that a new instance
# of Kookaburra is created for each individual test, otherwise you may wind up
# with test state bleeding over from one test to the next. The
# {Kookaburra::TestHelpers} module is intended to be mixed in to your testing
# context for this purpose.
#
# @see Kookaburra::TestHelpers
class Kookaburra
  extend Forwardable

  class << self
    # Stores the configuration object that is used by default when creating new
    # instances of Kookaburra
    #
    # @return [Kookaburra::Configuration] return value is memoized
    def configuration
      @configuration ||= Configuration.new
    end

    # Yields the current configuration so that it can be modified
    #
    # @yield [Kookaburra::Configuration]
    def configure(&blk)
      blk.call(configuration)
    end
  end

  # Returns a new Kookaburra instance that wires together your application's
  # APIDriver and UIDriver with a shared {Kookaburra::MentalModel}.
  #
  # @param [Kookaburra::Configuration] configuration (Kookaburra.configuration)
  def initialize(configuration = Kookaburra.configuration)
    self.configuration = configuration
  end

  # Returns an instance of your APIDriver class configured to share test
  # fixture data with the UIDriver
  #
  # @return [Kookaburra::APIDriver]
  def api
    @api ||= api_driver_class.new(configuration)
  end

  # Returns an instance of your UIDriver class configured to share test fixture
  # data with the APIDriver and to use the browser driver you specified in
  # {#initialize}
  #
  # @return [Kookaburra::UIDriver]
  def ui
    @ui ||= ui_driver_class.new(configuration)
  end

  # Returns a deep-dup of the specified {MentalModel::Collection}.
  #
  # This access is provided so that you can reference the current mental model
  # within your test implementation and make assertions about the state
  # of your application's interface.
  #
  # @example
  #   api.create_widget(:foo)
  #   ui.create_a_new_widget(:bar)
  #   ui.widget_list.widgets.should == k.get_data(:widgets).values_at(:foo, :bar)
  #
  # @return [Kookaburra::MentalModel::Collection]
  def get_data(collection_name)
    mental_model.send(collection_name).dup
  end

  private

  attr_accessor :configuration

  def_delegators :configuration, :api_driver_class, :ui_driver_class,
    :mental_model
end
