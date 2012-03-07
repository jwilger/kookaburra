require 'kookaburra/exceptions'
require 'kookaburra/dependency_accessor'

class Kookaburra
  class UIDriver
    class UIComponent
      extend DependencyAccessor

      dependency_accessor :browser

      def initialize(options = {})
        @browser = options[:browser]
        @server_error_detection = options[:server_error_detection]
      end

      def show(*args)
        return if visible?
        browser.visit component_path(*args)
        assert_visible
      end

      def visible?
        detect_server_error!
        browser.has_css?(component_locator)
      end

      private

      def assert(test, message = "You might want to provide a better message, eh?")
        test or raise AssertionFailed, message
      end

      def assert_visible
        assert visible?, "The #{self.class.name} component is not visible!"
      end

      def component_path
        raise ConfigurationError, "You must define #{self.class.name}#component_path."
      end

      def component_locator
        raise ConfigurationError, "You must define #{self.class.name}#component_locator."
      end

      def detect_server_error!
        if @server_error_detection.try(:call, browser)
          raise UnexpectedResponse, "Your server error detection function detected a server error. Looks like your applications is busted. :-("
        end
      end
    end
  end
end
