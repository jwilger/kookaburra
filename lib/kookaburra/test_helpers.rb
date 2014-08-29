require 'forwardable'
require 'kookaburra'
require 'kookaburra/mental_model_matcher'

class Kookaburra
  # This module is intended to be mixed in to your testing context to provide
  # convenient access to your Kookaburra objects. Examples for both RSpec and
  # Cucumber are given below; mixing it in to other test setups should be pretty
  # straight-forward.
  #
  # @example RSpec setup
  #   # in 'spec/support/kookaburra_setup.rb'
  #   require 'kookaburra/test_helpers'
  #   require 'my_app/kookaburra/given_driver'
  #   require 'my_app/kookaburra/ui_driver'
  #   
  #   Kookaburra.configure do |c|
  #     c.given_driver_class = myapp::kookaburra::givendriver,
  #     c.ui_driver_class = myapp::kookaburra::uidriver,
  #     c.app_host = 'http://my_app.example.com:12345',
  #     c.browser = capybara,
  #     c.server_error_detection { |browser|
  #       browser.has_css?('h1', text: 'internal server error')
  #     }
  #   end
  #
  #   RSpec.configure do |c|
  #     c.include(Kookaburra::TestHelpers, :type => :request)
  #   end
  #
  #   # in 'spec/request/some_feature_spec.rb'
  #   describe "Some Feature" do
  #     example "some test script" do
  #       given.a_widget(:foo)
  #       given.a_widget(:bar, :hidden => true)
  #       given.a_widget(:baz)
  #
  #       ui.view_list_of_widgets
  #
  #       ui.widget_list.widgets.should == k.get_data(:widgets).slice(:foo, :baz)
  #
  #       ui.widget_list.hide_widget(:foo)
  #
  #       ui.widget_list.widgets.should == k.get_data(:widgets).slice(:baz)
  #     end
  #   end
  #
  # @example Cucumber setup
  #   # in 'features/support/kookaburra_setup.rb'
  #   require 'kookaburra/test_helpers'
  #   require 'my_app/kookaburra/given_driver'
  #   require 'my_app/kookaburra/ui_driver'
  #   
  #   Kookaburra.configure do |c|
  #     c.given_driver_class = myapp::kookaburra::givendriver,
  #     c.ui_driver_class = myapp::kookaburra::uidriver,
  #     c.app_host = 'http://my_app.example.com:12345',
  #     c.browser = capybara,
  #     c.server_error_detection { |browser|
  #       browser.has_css?('h1', text: 'internal server error')
  #     }
  #   end
  #
  #   World(Kookaburra::TestHelpers)
  #
  #   # in 'features/step_definitions/some_steps.rb
  #   Given /^there is a widget, "(\w+)"/ do |name|
  #     given.a_widget(name.to_sym)
  #   end
  #
  #   Given /^there is a hidden widget, "(\w+)"/ do |name|
  #     given.a_widget(name.to_sym, :hidden => true)
  #   end
  #
  #   When /^I view the widget list/ do
  #     ui.view_the_widget_list
  #   end
  #
  #   Then /^I see the widget list contains the following widgets$/ do |widget_names|
  #     widgets = widget_names.hashes.map { |h| h['name'].to_sym }
  #     ui.widget_list.widgets.should == k.get_data(:widgets).slice(widgets)
  #   end
  module TestHelpers
    extend Forwardable

    # The {Kookaburra} instance to be used by your tests. It gets configured
    # using the options set in {Kookaburra.configuration}, and the result is
    # memoized.
    #
    # @return [Kookaburra]
    def k
      @k ||= Kookaburra.new
    end

    # @method given
    # Delegates to {#k}
    def_delegator :k, :given

    # @method ui
    # Delegates to {#k}
    def_delegator :k, :ui

    # #method api_client
    # Delegates to {#k}
    def_delegator :k, :api_client

    # RSpec-style custom matcher that compares a given array with
    # the current state of one named collection in the mental model
    #
    # @see Kookaburra::MentalModel::Matcher
    def match_mental_model_of(collection_key)
      MentalModel::Matcher.new(k.send(:__mental_model__), collection_key)
    end

    # Custom assertion for Test::Unit-style tests
    # (really, anything that uses #assert(predicate, message = nil))
    #
    # @see Kookaburra::MentalModel::Matcher
    def assert_mental_model_matches(collection_key, actual, message = nil)
      matcher = match_mental_model_of(collection_key)
      result = matcher.matches?(actual)
      return if !!result  # don't even bother

      message ||= matcher.failure_message_for_should
      assert result, message
    end
  end
end
