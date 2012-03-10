require 'kookaburra'

class Kookaburra
  # This module is intended to be mixed in to your testing context to provide
  # convenient access to your Kookaburra objects. Examples for both RSpec and
  # Cucumber are given below; mixing it in to other test setups should be pretty
  # straight-forward.
  #
  # @example RSpec setup
  #   # in 'spec/support/kookaburra_setup.rb'
  #   require 'kookaburra/test_helpers'
  #   require 'my_app/kookaburra/api_driver'
  #   require 'my_app/kookaburra/given_driver'
  #   require 'my_app/kookaburra/ui_driver'
  #   
  #   Kookaburra.configuration = {
  #     :given_driver_class => MyApp::Kookaburra::GivenDriver,
  #     :api_driver_class => MyApp::Kookaburra::APIDriver,
  #     :ui_driver_class => MyApp::Kookaburra::UIDriver,
  #     :browser => Capybara,
  #     :server_error_detection => lambda { |browser|
  #       browser.has_css?('h1', text: 'Internal Server Error')
  #     }
  #   }
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
  #   require 'my_app/kookaburra/api_driver'
  #   require 'my_app/kookaburra/given_driver'
  #   require 'my_app/kookaburra/ui_driver'
  #   
  #   Kookaburra.configuration = {
  #     :given_driver_class => MyApp::Kookaburra::GivenDriver,
  #     :api_driver_class => MyApp::Kookaburra::APIDriver,
  #     :ui_driver_class => MyApp::Kookaburra::UIDriver,
  #     :browser => Capybara,
  #     :server_error_detection => lambda { |browser|
  #       browser.has_css?('h1', text: 'Internal Server Error')
  #     }
  #   }
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
      @k ||= Kookaburra.new(Kookaburra.configuration)
    end

    # @method given
    # Delegates to {#k}
    delegate :given, :to => :k

    # @method ui
    # Delegates to {#k}
    delegate :ui, :to => :k
  end
end
