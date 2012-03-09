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

      def method_missing(name, *args, &block)
        element.send(name, *args, &block)
      end

      def respond_to?(name)
        super || element.respond_to?(name)
      end

      def show(*args)
        return if visible?
        browser.visit component_path(*args)
        assert_visible
      end

      def visible?
        element.visible?
      rescue ComponentNotFound
        false
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
