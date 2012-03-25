require 'kookaburra/dependency_accessor'
require 'kookaburra/ui_driver/ui_component'

class Kookaburra
  # You UIDriver subclass is where you define the DSL for testing your
  # application via its user interface. Methods defined in your DSL should
  # represent business actions rather than user interface manipulations. A
  # good test of this is whether the names of your methods would need to change
  # significantly if the application needed to be implemented in a vastly
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
  #
  # With larger applications, it may be beneficial to break down your business
  # actions into multiple classes. The top-level {UIDriver} can have sub-drivers
  # associated with it (and those can have sub-drivers, too; but let's not get
  # carried away, eh?):
  #
  #   class AccountManagementDriver < Kookaburra::UIDriver
  #     ui_component :account_list, AccountList
  #     # ...
  #   end
  #
  #   class MyUIDriver < Kookaburra::UIDriver
  #     ui_driver :account_management, AccountManagementDriver
  #     # ...
  #   end
  #
  # In your test implementation, you can then do (among other things):
  #
  #   ui.account_management.account_list.should be_visible
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
          component_class.new(options.slice(:browser, :server_error_detection, :app_host))
        end
      end

      # Tells the UIDriver about sub-drivers (other {UIDriver} subclasses).
      #
      # @param [Symbol] driver_name Will create an instance method of this
      #   name that returns an instance of the driver_class
      # @param [Class] driver_class The {UIDriver} subclass that defines
      #   this driver.
      def ui_driver(driver_name, driver_class)
        define_method(driver_name) do
          driver_class.new(options.slice(:browser, :server_error_detection, :app_host, :mental_model))
        end
      end
    end

    # It is unlikely that you would instantiate your UIDriver on your own; the
    # object is configured for you when you call {Kookaburra#ui}.
    #
    # @option options [Capybara::Session] :browser Most likely a
    #   `Capybara::Session` instance.
    # @option options [Kookaburra::MentalModel] :mental_model
    # @option options [String] :app_host The root URL of your running
    #   application (e.g. "http://my_app.example.com:12345")
    # @option options [Proc] :server_error_detection A lambda that is passed the
    #   `:browser` object and should return `true` if the page indicates a server
    #   error has occured
    def initialize(options = {})
      @options = options
      @mental_model = options[:mental_model]
    end

    protected

    # Provides access to the options with which the object was initialized
    attr_reader :options

    # @attribute [r] mental_model
    dependency_accessor :mental_model
  end
end
