require 'kookaburra/test_data'
require 'kookaburra/api_driver'
require 'kookaburra/given_driver'
require 'kookaburra/ui_driver'

# This module contains the methods for Kookaburra configuration as well as
# accessors to the `GivenDriver`, `APIDriver` and `UIDriver`. See
# {file:README.markdown README} for more information on setting up Kookaburra
# for your project.
module Kookaburra
  class << self
    # Provides the default adapter for the Kookaburra library.
    #
    # If not using Capybara, the Object must respond to `#app` and return a Rack
    # application; and it must respond to `#current_session` and return an
    # object that provides the same interface as `Capybara::Session`
    #
    # @example using Capybara
    #     Kookaburra.adapter = Capybara
    attr_accessor :adapter

    # A reference to your application's subclass of `Kookaburra::APIDriver`
    #
    # @example setting your APIDriver
    #     Kookaburra.api_driver = MyApplication::Kookaburra::APIDriver
    attr_accessor :api_driver

    # A reference to your application's subclass of `Kookaburra::GivenDriver`
    #
    # @example setting your GivenDriver
    #     Kookaburra.api_driver = MyApplication::Kookaburra::GivenDriver
    attr_accessor :given_driver

    # A reference to your application's subclass of `Kookaburra::UIDriver`
    #
    # @example setting your UIDriver
    #     Kookaburra.api_driver = MyApplication::Kookaburra::UIDriver
    attr_accessor :ui_driver

    # Configure the test data collections and default data for your tests
    #
    # The passed block is evaluated in the context of the `Kookaburra::TestData`
    # class and therefore has access to the
    # `Kookaburra::TestData.provide_collection` and
    # `Kookaburra::TestData.default` methods. Anything else in the block will
    # also be evaluated in the context of the class, allowing you to further
    # augment the TestData class.
    #
    # @param [Proc] blk the TestData configuration code
    #
    # @example creating a collection
    #     Kookaburra.test_data_setup do
    #       provide_collection :users
    #     end
    #
    # @example specifying default values for use in tests
    #     Kookaburra.test_data_setup do
    #       default :user,
    #         :first_name => 'Bob',
    #         :last_name  => 'Jones',
    #         :password   => 'bob_jones_password'
    #       end
    #     end
    #
    # @example otherwise extending TestData
    #     Kookaburra.test_data_setup do
    #       include MyApplication::Kookaburra::TestDataExtensions
    #     end
    #
    # @see Kookaburra::TestData.provide_collection
    # @see Kookaburra::TestData.default
    def test_data_setup(&blk)
      Kookaburra::TestData.class_eval(&blk)
    end
  end

  # Used to override Kookaburra.adapter in Kookaburra's own tests.
  #
  # This method should not be used by applications using Kookaburra.
  #
  # @private
  attr_accessor :kookaburra_adapter

  def kookaburra_adapter
    @kookaburra_adapter ||= Kookaburra.adapter
  end

  # The configured instance of the `Kookaburra::APIDriver` subclass for your
  # application.
  #
  # Can be used in the Test Implementation layer to access the application's API
  # directly, however you should probably only call this within your
  # `GivenDriver`.
  #
  # @return [Kookaburra::APIDriver]
  def api
    kookaburra_drivers[:api] ||= Kookaburra.api_driver.new(:app => kookaburra_adapter.app)
  end

  # The configured instance of the `Kookaburra::GivenDriver` subclass for your
  # application.
  #
  # Use #given inside your test implementation to call methods from your
  # `GivenDriver` subclass.
  #
  # @return [Kookaburra::GivenDriver]
  def given
    kookaburra_drivers[:given] ||= \
      Kookaburra.given_driver.new(:api_driver => api, :test_data => kookaburra_test_data)
  end

  # The configured instance of the `Kookaburra::UIDriver` subclass for your
  # application.
  #
  # Use #given inside your test implementation to call methods from your
  # `UIDriver` subclass.
  #
  # @return [Kookaburra::UIDriver]
  def ui
    kookaburra_drivers[:ui] ||= Kookaburra.ui_driver.new(
      :browser => kookaburra_adapter.current_session,
      :test_data => kookaburra_test_data)
  end

  # Reset the Kookaburra drivers to clear state between Cucumber scenarios
  #
  # This method causes new instances of all the Kookaburra drivers to be created
  # the next time they are used, and, in particular, resets the state of any
  # test data that is shared between the various drivers. This is necessary when
  # Kookaburra is mixed in to Cucumber's World, because World does not get a new
  # instance for each scenario.
  #
  # @example add this to `features/support/kookaburra_setup.rb`
  #   Before do
  #     kookaburra_reset!
  #   end
  def kookaburra_reset!
    @kookaburra_drivers = {}
  end

  private

  # The Kookaburra::TestData instance should not be accesed directly in the test
  # implementation layer, but all of the drivers should reference the same
  # instance.
  def kookaburra_test_data
    kookaburra_drivers[:test_data] ||= Kookaburra::TestData.new
  end

  # Holds references to all drivers in a single hash, so that
  # `Kookaburra#kookaburra_reset!` can clear all Kookaburra state on the
  # instance of the including class.
  def kookaburra_drivers
    @kookaburra_drivers ||= {}
  end
end
