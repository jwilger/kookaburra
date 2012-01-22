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
    # Provides the default adapter for the Kookaburra library. In most cases,
    # this will probably be the `Capybara` class:
    #
    #   Kookaburra.adapter = Capybara
    #
    # Whatever object is passed in must respond to `#app` and return a Rack
    # application; and it must respond to `#current_session` and return an
    # object that provides the same interface as `Capybara::Session`
    attr_accessor :adapter

    # The API Driver that will be used by Kookaburra, typically a subclass of
    # Kookaburra::APIDriver containing the testing DSL for your app. The default
    # is an instance of Kookaburra::APIDriver.
    attr_accessor :api_driver

    def api_driver
      @api_driver ||= Kookaburra::APIDriver
    end

    # The Given Driver that will be used by Kookaburra, typically a subclass of
    # Kookaburra::GivenDriver containing the testing DSL for your app. The default
    # is an instance of Kookaburra::GivenDriver.
    attr_accessor :given_driver

    def given_driver
      @given_driver ||= Kookaburra::GivenDriver
    end

    # The UI Driver that will be used by Kookaburra, typically a subclass of
    # Kookaburra::UIDriver containing the testing DSL for your app. The default
    # is an instance of Kookaburra::UIDriver.
    attr_accessor :ui_driver

    def ui_driver
      @ui_driver ||= Kookaburra::UIDriver
    end

    def test_data_setup(&blk)
      Kookaburra::TestData.class_eval(&blk)
    end
  end

  # Whatever was set in `Kookaburra.adapter can be overriden in the mixin
  # context. For example, in an RSpec example:
  #
  #   describe "Something" do
  #     it "does something" do
  #       self.kookaburra_adapter = CapybaraLikeThing
  #       ...
  #     end
  #   end
  #
  attr_accessor :kookaburra_adapter

  def kookaburra_adapter
    @kookaburra_adapter ||= Kookaburra.adapter
  end

  # Returns a configured instance of the `Kookaburra::APIDriver`
  def api
    kookaburra_drivers[:api] ||= Kookaburra.api_driver.new(
      :app => kookaburra_adapter.app,
      :test_data => kookaburra_test_data)
  end

  # Returns a configured instance of the `Kookaburra::GivenDriver`
  def given
    kookaburra_drivers[:given] ||= Kookaburra.given_driver.new(:api_driver => api)
  end

  # Returns a configured instance of the `Kookaburra::UIDriver`
  def ui
    kookaburra_drivers[:ui] ||= Kookaburra.ui_driver.new(
      :browser => kookaburra_adapter.current_session,
      :test_data => kookaburra_test_data)
  end

  # This method causes new instances of all the Kookaburra drivers to be created
  # the next time they are used, and, in particular, resets the state of any
  # test data that is shared between the various drivers. This is necessary when
  # Kookaburra is mixed in to Cucumber's World, because World does not get a new
  # instance for each scenario. Instead, just be sure to call this method from a
  # `Before` block in your cucumber setup, i.e.:
  #
  #   Before do
  #     kookaburra_reset!
  #   end
  def kookaburra_reset!
    @kookaburra_drivers = {}
  end

  private

  # The Kookaburra::TestData instance should not be used directly, but all of
  # the drivers should reference the same instance.
  def kookaburra_test_data
    kookaburra_drivers[:test_data] ||= Kookaburra::TestData.new
  end

  # Holds references to all drivers in a single hash, so that
  # Kookaburra#kookaburra_reset! can easily clear all Kookaburra state on the
  # instance of the including class.
  def kookaburra_drivers
    @kookaburra_drivers ||= {}
  end
end
