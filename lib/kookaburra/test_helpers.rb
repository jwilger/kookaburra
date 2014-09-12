require 'forwardable'
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
  #   require 'my_app/kookaburra/ui_driver'
  #
  #   Kookaburra.configure do |c|
  #     c.api_driver_class = MyApp::Kookaburra::APIDriver,
  #     c.ui_driver_class = MyApp::Kookaburra::UIDriver,
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
  #       api.create_widget(:foo)
  #       api.create_widget(:bar, :hidden => true)
  #       api.create_widget(:baz)
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
  #   require 'my_app/kookaburra/ui_driver'
  #
  #   Kookaburra.configure do |c|
  #     c.api_driver_class = MyApp::Kookaburra::APIDriver,
  #     c.ui_driver_class = MyApp::Kookaburra::UIDriver,
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
  #     api.create_widget(name.to_sym)
  #   end
  #
  #   Given /^there is a hidden widget, "(\w+)"/ do |name|
  #     api.create_widget(name.to_sym, :hidden => true)
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
      unless Kookaburra.configuration.applications.empty?
        raise AmbiguousDriverError
      end
      kookaburra_instance
    end

    # @method api
    # Delegates to {#k}
    def_delegator :k, :api

    # @method ui
    # Delegates to {#k}
    def_delegator :k, :ui

    # @method get_data
    # Delegates to {Kookaburra} instance
    def_delegator :kookaburra_instance, :get_data

    def method_missing(method_name, *args, &block)
      Kookaburra.configuration.applications[method_name.to_sym] \
        || super
    end

    def respond_to?(method_name)
      Kookaburra.configuration.applications.has_key?(method_name) \
        || super
    end

    private

    def kookaburra_instance
      @kookaburra_instance ||= Kookaburra.new
    end
  end
end
