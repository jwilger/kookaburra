require 'kookaburra'
require 'kookaburra/mental_model_matcher'
require 'active_support/core_ext/module/delegation'

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
    delegate :given, :to => :k

    # @method ui
    # Delegates to {#k}
    delegate :ui, :to => :k

    # RSpec-style custom matcher that compares an observed result with
    # the current state of one named collection in the mental model.
    #
    # This matcher can be used in two different ways.
    #
    # 1) If the matcher is called on an Array, a direct comparison will be
    # done between the Array and the MentalModel collection (after any
    # specified scoping or mapping methods have) been applied.
    #
    # 2) If the matcher is called on an object that responds to the
    # collection_method (which defaults to the collection_key but can be
    # overridden with "#using"), the result of actual#collection_method will
    # be used for the comparison.
    #
    # When using method #2, if the match is unsuccessful, failure won't be
    # reported immediately; instead, the comparison will be retried
    # continuously for the number of seconds specified by wait_for (see
    # "#initialize").  This is the recommended usage, and is useful for taking
    # into account possible rendering delays.
    #
    # @example Comparing against an array
    #   mental_model.widgets = { :foo => foo, :bar => bar }
    #   [foo, bar].should match_mental_model_of(:widgets)
    # @example Comparing against an object that responds to the collection_key
    #   mental_model.widgets = { :foo => foo, :bar => bar }
    #   widget_index.widgets = [foo, bar]
    #   widget_index.should match_mental_model_of(:widgets)
    # @example Comparing against an object that responds to an alternate key
    #   mental_model.widgets = { :foo => foo, :bar => bar }
    #   widget_index.visible_widgets = [foo, bar]
    #   widget_index.should match_mental_model_of(:widgets).using(:visible_widgets)
    #
    # @param [Symbol] collection_key The key of the collection on the
    #   mental model that represents the observed result we want.
    #
    # @see Kookaburra::MentalModel::Matcher
    def match_mental_model_of(collection_key)
      MentalModel::Matcher.new(k.send(:__mental_model__), collection_key)
    end

    # Custom assertion for Test::Unit-style tests
    # (really, anything that uses #assert(predicate, message = nil))
    #
    # This is essentially a wrapper of match_mental_model_of.
    #
    # @param [Symbol] collection_key The key of the collection on the
    #   mental model that represents the observed result we want.
    # @param [Array, #collection_method] actual This is the data observed
    #   (or an object that returns the data observed when called with
    #   collection_method) that you you are attempting to match against the
    #   mental model.
    # @param [message] message Message to return in case of failure; if not
    #   specified, will return message describing differences between expected
    #   and actual.
    # @param [options] options Hash of scoping/filtering blocks to call on
    #   matcher (for limiting collection data to compare against) before
    #   attempting match.  See the Matcher for details.
    # @see Kookaburra::MentalModel::Matcher
    def assert_mental_model_matches(collection_key, actual, message = nil, options = {})
      matcher = match_mental_model_of(collection_key)
      options.each_pair do |key, val|
        matcher = matcher.send(key.to_sym, &val)
      end
      result = matcher.matches?(actual)
      return if !!result  # don't even bother

      message ||= matcher.failure_message_for_should
      assert result, message
    end
  end
end
