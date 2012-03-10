require 'kookaburra/exceptions'
require 'kookaburra/dependency_accessor'

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
    # `#click_button` are forwarded to the {#element} object (see
    # {#method_missing}) and are therefore automatically scoped to the
    # component's DOM element. Although it is possible to reach outside this
    # scope by calling methods on {#browser} (e.g. `browser.click_on "Foo"`),
    # this should be avoided, because you'll end up with a tangled mess of
    # UIComponents without clear responsibilities. 
    #
    # @abstract Subclass and implement (at least) {#component_locator}. Unless
    #   you override the default implementation of {#show}, you must also
    #   override the {#component_path} method.
    class UIComponent
      extend DependencyAccessor

      # New UIComponent instances are typically created for you by your
      # {Kookaburra::UIDriver} instance.
      #
      # @see Kookaburra::UIDriver.ui_component
      #
      # @option options [Capybara::Session] :browser 
      # @option options [Proc] :server_error_detection
      def initialize(options = {})
        @browser = options[:browser]
        @server_error_detection = options[:server_error_detection]
      end

      # If the UIComponent is sent a message it does not understand, it will
      # forward that message on to its {#element}. This give you convenient
      # access to the browser driver's DSL, automatically scoped to this
      # component.
      #
      # @raise [Kookaburra::ComponentNotFound] raised from {#element}
      def method_missing(name, *args, &block)
        if element.respond_to?(name)
          element.send(name, *args, &block)
        else
          super
        end
      end

      # @private
      # Behaves as you might expect given #method_missing
      def respond_to?(name)
        super || element.respond_to?(name)
      end

      # Causes the UIComponent to be visible.
      #
      # Causes the browser to navigate directly to {#component_path} (unless the
      # component is already visible).
      #
      # You may need to override this method in your own UIComponent subclasses,
      # especially for components that are dynamically added/removed on the page
      # in response to user actions.
      #
      # @param args Any arguments are passed to the {#component_path} method.
      def show(*args)
        return if visible?
        browser.visit component_path(*args)
        assert visible?, "The #{self.class.name} component is not visible!"
      end

      # True if the component's element is found on the page and is considered
      # "visible" by the browser driver.
      def visible?
        element.visible?
      rescue ComponentNotFound
        false
      end

      protected

      # This is the browser driver with which the UIComponent was initialized.
      #
      # You almost certainly want to reference {#element} instead, as it is
      # scoped to this component's DOM element, whereas #browser is not scoped.
      #
      # @attribute [r] browser
      #
      # @raise [RuntimeError] if no browser was specified in call to {#initialize}
      dependency_accessor :browser

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
      def component_path
        raise ConfigurationError, "You must define #{self.class.name}#component_path."
      end

      # @abstract
      # @return [String] the CSS3 selector that will find the element in the DOM
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

      # Provides access to the element found by the browser driver at
      # {#component_locator}. If your browser driver is a `Capybara::Session`,
      # then this will be a `Capybara::Node::Element`.
      #
      # @raise [UnexpectedResponse] from {#detect_server_error!}
      # @raise [ComponentNotFound] if the {#component_locator} is not found in
      #   the DOM
      #
      # @return [Capybara::Node::Element]
      def element
        detect_server_error!
        begin
          browser.find(component_locator)
        rescue StandardError => e
          raise ComponentNotFound, e.message
        end
      end
    end
  end
end
