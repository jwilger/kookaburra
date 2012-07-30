require 'delegate'
require 'kookaburra/exceptions'
require 'kookaburra/assertion'
require 'kookaburra/ui_driver/has_ui_components'
require 'kookaburra/ui_driver/scoped_browser'

class Kookaburra
  class UIDriver
    # UIComponent is intended to be subclassed to represent each component of
    # your application-under-test's user interface. The purpose of the
    # UIComponent object is to abstract away the implementation details of your
    # interface when testing and allow you to concentrate on testing your
    # business requirements. For instance, a UIComponent subclass for your
    # sign-up form might have accessors for the individual fields as well as
    # methods that allow you to perform distinct operations:
    #
    # @example SignUpForm component
    #   class SignUpForm < Kookaburra::UIDriver::UIComponent
    #     def component_path
    #       '/signup'
    #     end
    #
    #     def component_locator
    #       '#sign_up_form'
    #     end
    #
    #     def email
    #       find('#user_email').value
    #     end
    #
    #     def email=(new_email)
    #       fill_in 'user_email', :with => new_email
    #     end
    #
    #     def password
    #       find('#user_password').value
    #     end
    #
    #     def password=(new_password)
    #       fill_in 'user_password', :with => new_password
    #     end
    #
    #     def password_confirmation
    #       find('#user_password_confirmation').value
    #     end
    #
    #     def password_confirmation=(new_password_confirmation)
    #       fill_in 'user_password_confirmation', :with => new_password_confirmation
    #     end
    #
    #     def submit
    #       click_button 'Sign Up'
    #     end
    #
    #     def sign_up(data = {})
    #       self.email = data[:email]
    #       self.password = data[:password]
    #       self.password_confirmation = data[:password_confirmation]
    #       submit
    #     end
    #   end
    #
    # Note that the "browser operation" methods such as `#fill_in` and
    # `#click_button` are delegated to a {ScopedBrowser} and are
    # automatically scoped to the component's DOM element.    
    #
    # @note Even though a `UIComponent` should respond to all of the
    #   methods on the browser (i.e. all of the Capybara DSL methods),
    #   for some reason call to `#select` get routed to `Kernel#select`.
    #   You can get around this by calling it as `self.select`. See
    #   https://gist.github.com/3192103 for an example of this behavior.
    #
    # @abstract Subclass and implement (at least) {#component_locator}. Unless
    #   you override the default implementation of {#url}, you must also
    #   override the {#component_path} method.
    class UIComponent < SimpleDelegator
      include Assertion
      extend HasUIComponents

      # The {Kookaburra::Configuration} with which the component
      # instance was instantiated.
      attr_reader :configuration

      # The options Hash with which the component instance was
      # instantiated.
      attr_reader :options

      # New UIComponent instances are typically created for you by your
      # {Kookaburra::UIDriver} instance.
      #
      # @see Kookaburra::UIDriver.ui_component
      #
      # @param [Kookaburra::Configuration] configuration
      # @param [Hash] options An options hash that can be used to
      #   further configure a `UIComponent`'s behavior.
      def initialize(configuration, options = {})
        @configuration = configuration
        @options = options
        @browser = configuration.browser
        @app_host = configuration.app_host
        @server_error_detection = configuration.server_error_detection
        scoped_browser = ScopedBrowser.new(@browser, lambda { component_locator })
        super(scoped_browser)
      end

      # Is the component's element found on the page and is it considered
      # "visible" by the browser driver.
      def visible?
        visible = browser.has_css?(component_locator, :visible)
        unless visible
          detect_server_error!
        end
        visible
      end

      # Returns the full URL by appending {#component_path} to the value of the
      # {Kookaburra::Configuration#app_host} from the initialized configuration.
      def url(*args)
        "#{@app_host}#{component_path(*args)}"
      end

      protected

      # The browser object from the initialized configuration
      attr_reader :browser

      # @abstract
      # @return [String] the URL path that should be loaded in order to reach this component
      # @raise [Kookaburra::ConfigurationError] raised if you haven't provided
      #   an implementation
      def component_path
        raise ConfigurationError, "You must define #{self.class.name}#component_path."
      end

      # @abstract
      # @return [String] the CSS3 selector that will find the element in the DOM
      # @raise [Kookaburra::ConfigurationError] raised if you haven't provided
      #   an implementation
      def component_locator
        raise ConfigurationError, "You must define #{self.class.name}#component_locator."
      end

      # Runs the server error detection function specified in
      # {Kookaburra::Configuration#server_error_detection}.
      #
      # It's a noop if no server error detection was specified.
      #
      # @raise [UnexpectedResponse] raised if the server error detection
      #   function returns true
      def detect_server_error!
        return if @server_error_detection.nil?
        if @server_error_detection.call(browser)
          raise UnexpectedResponse, "Your server error detection function detected a server error. Looks like your applications is busted. :-("
        end
      end
    end
  end
end
