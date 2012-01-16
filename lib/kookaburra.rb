require File.join(File.dirname(__FILE__), *%w[requires])

# Kookaburra is a framework for implementing the WindowDriver pattern in order
# to keep acceptance tests maintainable.
#
# For RSpec integration tests, just add the following to
# `spec/support/kookaburra.rb`:
# 
#   RSpec.configure do |c|
#     c.include(Kookaburra, :type => :request)
#   end
#
# That will make #given, #api and #ui entry-points available to your examples,
# e.g.:
#
#   describe "Widget Management" do
#     describe "viewing a list of widgets" do
#       example "when there are no widgets" do
#         given.there_is_a_user(:bob)
#         given.user_has_no_widgets(:bob)
#
#         ui.log_in_as(:bob)
#         ui.navigate_to(:list_of_widgets)
#
#         ui.list_of_widgets.should be_visible
#         ui.list_of_widgets.should be_empty
#       end
#     end
#   end
#
# For Cucumber, add the following to `features/support/kookaburra_setup.rb`:
#
#   Kookaburra.adapter = Capybara
#   World(Kookaburra)
#
#   Before do
#     kookaburra_reset!
#   end
#
# After doing to, the #api, #given and #ui methods will be available in your
# Cucumber step definitions.
#
# (Obviously, the specific methods on #given and #ui are something that will be
# unique to your application's domain.)
module Kookaburra
  class << self
    # Provides the default adapter for the Kookaburra library. In most cases,
    # this will probably be the `Capybara` class:
    #
    #   Kookaburra.adapter = Capybara
    #
    # We allow this to be passed in, so that we can avoid a hard-coded
    # dependency on Capybara in this gem.
    attr_accessor :adapter
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

  def kookaburra_adapter #:nodoc:
    @kookaburra_adapter ||= Kookaburra.adapter
  end

  # Returns a configured instance of the `Kookaburra::APIDriver`
  def api
    kookaburra_drivers[:api] ||= Kookaburra::APIDriver.new(
      :app => kookaburra_adapter.app,
      :test_data => kookaburra_test_data)
  end

  # Returns a configured instance of the `Kookaburra::GivenDriver`
  def given
    kookaburra_drivers[:given] ||= Kookaburra::GivenDriver.new(:api_driver => api)
  end

  # Returns a configured instance of the `Kookaburra::UIDriver`
  def ui
    kookaburra_drivers[:ui] ||= Kookaburra::UIDriver.new(
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
