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
    #     # If it can't be inferred from the class name
    #     def component_locator
    #       '#user-sign-up'
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
    # Note that the "browser operation" methods such as {#fill_in} and
    # {#click_button} are delegated to a {ScopedBrowser} and are
    # automatically scoped to the component's DOM element.
    #
    # @note Even though a {UIComponent} should respond to all of the
    #   methods on the browser (i.e. all of the Capybara DSL methods),
    #   for some reason call to {#select} get routed to {Kernel#select}.
    #   You can get around this by calling it as `self.select`. See
    #   https://gist.github.com/3192103 for an example of this behavior.
    #
    # @abstract Unless you override the default implementation of {#url}, you
    #   must override the {#component_path} method if you want the component to
    #   be navigable by the {Kookaburra::UIDriver::UIComponent::AddressBar}
    #   component.
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
      #   further configure a {UIComponent}'s behavior.
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
        visible = browser.has_css?(component_locator, visible: true)
        unless visible
          detect_server_error!
        end
        visible
      end

      def not_visible?
        browser.has_no_css?(component_locator, visible: true)
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

      # The CSS3 selector that will find the element in the DOM
      #
      # Defaults to a "#" followed by the snake-cased (underscored) version of
      # the class name with '/' replaced by '-'. Override this method in your
      # subclasses if you need a different CSS3 selector to find your component.
      #
      # @example
      #   class My::Awesome::ComponentThingy < Kookaburra::UIDriver::UIComponent
      #   end
      #
      #   x = My::Awesome::ComponentThingy.allocate
      #   x.send(:component_locator)
      #   #=> '#my-awesome-component_thingy'
      #
      # @return [String]
      def component_locator
        "#" + self.class.name.gsub(/::/, '/').
          gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').
          tr("-", "_").
          gsub('/', '-').
          downcase
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
          raise UnexpectedResponse, "Server Error Detected:\n#{browser.text}"
        end
      end

      protected

      # Provides a reference to the HTML element represented by this UIComponent
      #
      # This is useful for getting at attributes of the current element, because
      # the normal find methods are scoped to run *inside* this element.
      #
      # @return Capybara::Element
      def this_element
        browser.find(component_locator)
      end

      private

      # As of Ruby 2.1.0, 'SimpleDelegator' delegates the '#raise' method to the
      # underlying object. Since our underlying object is probably a
      # 'BasicObject' that doesn't define '#raise', things get confusing as we
      # end up in a maze of '#method_missing' BS. This fixes it.
      def raise(*args)
        Kernel.raise(*args)
      end
    end
  end
end
