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
# (Obviously, the specific methods on #given and #ui are something that will be
# unique to your application's domain.)
#
module Kookaburra
  class << self
    # Provides the default adapter for the Kookaburra library. In most cases,
    # this will probably be the `Capybara` class:
    #
    #   Kookaburra.adapter = Capybara
    #
    # We allow this to be passed in, so that we can avoid a hard-coded
    # dependency on Capybara in this gem.
    #
    # (Note: the #drivers method still has a hard-coded dependency on Capybara,
    # but it is deprecated and will be removed shortly.)
    attr_accessor :adapter

    # This method is used by some Cucumber clients, but should be considered
    # deprecated.
    # TODO: find a better way to make sure the #given, #api and #ui methods are
    # available to Cucumber step definitions
    def drivers
      test_data = Kookaburra::TestData.new
      api_driver = Kookaburra::APIDriver.new({
        :app       => Capybara.app,
        :test_data => test_data,
      })
      given_driver = Kookaburra::GivenDriver.new({
        :api_driver => api_driver,
      })
      ui_driver = Kookaburra::UIDriver.new({
        :browser   => Capybara.current_session,
        :test_data => test_data,
      })
      { :api_driver => api_driver, :given_driver => given_driver, :ui_driver => ui_driver }
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

  def kookaburra_adapter #:nodoc:
    @kookaburra_adapter ||= Kookaburra.adapter
  end

  # Returns a configured instance of the `Kookaburra::APIDriver`
  def api
    @kookaburra_api ||= Kookaburra::APIDriver.new(:app => kookaburra_adapter.app,
                                                  :test_data => kookaburra_test_data)
  end

  # Returns a configured instance of the `Kookaburra::GivenDriver`
  def given
    @kookaburra_given ||= Kookaburra::GivenDriver.new(:api_driver => api)
  end

  # Returns a configured instance of the `Kookaburra::UIDriver`
  def ui
    @kookaburra_ui ||= Kookaburra::UIDriver.new(
      :browser => kookaburra_adapter.current_session,
      :test_data => kookaburra_test_data)
  end

  private

  # The Kookaburra::TestData instance should not be used directly, but all of
  # the drivers should reference the same instance.
  def kookaburra_test_data
    @kookaburra_test_data ||= Kookaburra::TestData.new
  end
end
