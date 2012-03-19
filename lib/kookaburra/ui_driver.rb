require 'kookaburra/dependency_accessor'
require 'kookaburra/ui_driver/ui_component'

class Kookaburra
  # You UIDriver subclass is where you define the DSL for testing your
  # application via its user interface. Methods defined in your DSL should
  # represent business processes rather than user interface manipulations. A
  # good test of this is whether the names of your methods would need to change
  # significantly if the business process needed to be implemented in a vastly
  # different manner (a text-only terminal app vs. a web app, for instance).
  #
  # @abstract Subclass and implement your UI testing DSL
  #
  # @example UIDriver subclass
  #   module MyApp
  #     module Kookaburra
  #       class UIDriver < ::Kookaburra::UIDriver
  #         ui_component :widget_list, WidgetList
  #         ui_component :questionnaire, Questionnaire
  #
  #         def view_the_widgets
  #           widget_list.show
  #         end
  #
  #         def view_all_of_the_widgets
  #           widget_list.show(:include_hidden => true)
  #         end
  #
  #         def complete_the_widget_questionnaire(answers = {})
  #           questionnaire.show
  #           questionnaire.page_1.submit(answers[:page_1])
  #           questionnaire.page_2.submit(answers[:page_2])
  #           questionnaire.page_3.submit(answers[:page_3])
  #           questionnaire.submit
  #         end
  #       end
  #     end
  #   end
  class UIDriver
    extend DependencyAccessor

    class << self
      # Tells the UIDriver about your {UIComponent} subclasses.
      #
      # @param [Symbol] component_name Will create an instance method of this
      #   name that returns an instance of the component_class
      # @param [Class] component_class The {UIComponent} subclass that defines
      #   this component.
      def ui_component(component_name, component_class)
        define_method(component_name) do
          component_class.new(:browser => @browser, :server_error_detection => @server_error_detection,
                              :app_host => @app_host)
        end
      end
    end

    # It is unlikely that you would instantiate your UIDriver on your own; the
    # object is configured for you when you call {Kookaburra#ui}.
    #
    # @option options [Object] browser Most likely a `Capybara::Session`
    #   instance.
    # @option options [Kookaburra::TestData] test_data
    # @option options [Proc] server_error_detection A lambda that is passed the
    #   `browser` object and should return `true` if the page indicates a server
    #   error has occured
    def initialize(options = {})
      @browser = options[:browser]
      @app_host = options[:app_host]
      @test_data = options[:test_data]
      @server_error_detection = options[:server_error_detection]
    end

    protected

    # @attribute [r] test_data
    dependency_accessor :test_data
  end
end
