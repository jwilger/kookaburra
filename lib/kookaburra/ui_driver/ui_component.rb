require 'kookaburra/exceptions'

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
    # `#click_button` are forwarded to the {#browser} object (see
    # {#method_missing}) and are automatically scoped to the component's DOM
    # element.    
    #
    # @abstract Subclass and implement (at least) {#component_locator}. Unless
    #   you override the default implementation of {#show}, you must also
    #   override the {#component_path} method.
    class UIComponent
      # New UIComponent instances are typically created for you by your
      # {Kookaburra::UIDriver} instance.
      #
      # @see Kookaburra::UIDriver.ui_component
      #
      # @option options [Capybara::Session] :browser This is the browser driver
      #   that allows you to interact with the web application's interface.
      # @option options [String] :app_host The root URL of your running
      #   application (e.g. "http://my_app.example.com:12345")
      # @option options [Proc] :server_error_detection A proc that will receive
      #   the object passed in to the :browser option as an argument and must
      #   return `true` if the server responded with an unexpected error or
      #   `false` if it did not.
      def initialize(options = {})
        @browser = options[:browser]
        @app_host = options[:app_host]
        @server_error_detection = options[:server_error_detection]
      end

      # If the UIComponent is sent a message it does not understand, it will
      # forward that message on to its {#browser} but wrap the call in a block
      # provided to the the browser's `#within` method. This provides convenient
      # access to the browser driver's DSL, automatically scoped to this
      # component.
      def method_missing(name, *args, &block)
        if respond_to?(name)
          browser.within(component_locator) do
            browser.send(name, *args, &block)
          end
        else
          super
        end
      end

      # @private
      # (Not really private, but YARD seemingly lacks RDoc's :nodoc tag, and the
      # semantics here don't differ from Object#respond_to?)
      def respond_to?(name)
        super || browser.respond_to?(name)
      end

      # Causes the UIComponent to be visible.
      #
      # The browser to navigates directly to {#component_path} (unless the
      # component is already visible).
      #
      # You may need to override this method in your own UIComponent subclasses,
      # especially for components that are dynamically added/removed on the page
      # in response to user actions. The implementation should not make any
      # assumptions about the current state of the user interface before it is
      # invoked.
      #
      # @param args Any arguments are passed to the {#component_path} method.
      #
      # @raise [RuntimeError] if the component is not visible after attempting
      #   to make it so.
      def show(*args)
        return if visible?
        browser.visit component_url(*args)
        assert visible?, "The #{self.class.name} component is not visible!"
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

      protected

      # This is the browser driver with which the UIComponent was initialized.
      # 
      # If no :browser option was specified in {#initialize}, it returns a
      # default {Kookaburra::NullBrowser} instance.
      def browser
        @browser ||= NullBrowser.new
      end

      # Provides a mechanism to make assertions about the state of your
      # UIComponent without relying on a specific testing framework. A good
      # reason to use this would be to provide a more informative error message
      # when a pre-condition is not met, rather than waiting on an operation
      # further down the line to fail.
      #
      # @param test an expression that will be evaluated in a boolean context
      # @param [String] message the exception message that will be used if
      #   test is false
      #
      # @raise [Kookaburra::AssertionFailed] raised if test evaluates to false
      def assert(test, message = "You might want to provide a better message, eh?")
        test or raise AssertionFailed, message
      end

      # @abstract
      # @return [String] the URL path that should be loaded in order to reach this component
      # @raise [Kookaburra::ConfigurationError] raised if you haven't provided
      #   an implementation
      def component_path
        raise ConfigurationError, "You must define #{self.class.name}#component_path."
      end

      # Returns the full URL by appending {#component_path} to the value of the
      # :app_host option passed to {#initialize}.
      def component_url(*args)
        "#{@app_host}#{component_path(*args)}"
      end

      # @abstract
      # @return [String] the CSS3 selector that will find the element in the DOM
      # @raise [Kookaburra::ConfigurationError] raised if you haven't provided
      #   an implementation
      def component_locator
        raise ConfigurationError, "You must define #{self.class.name}#component_locator."
      end

      # Runs the server error detection function specified in {#initialize}.
      #
      # It's a noop if no server error detection was specified.
      #
      # @raise [UnexpectedResponse] raised if the server error detection
      #   function returns true
      def detect_server_error!
        if @server_error_detection.try(:call, browser)
          raise UnexpectedResponse, "Your server error detection function detected a server error. Looks like your applications is busted. :-("
        end
      end
    end
  end
end
