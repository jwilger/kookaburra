require 'kookaburra/exception_classes'
require 'kookaburra/dependency_accessor'

class Kookaburra
  class UIDriver
    class UIComponent
      extend DependencyAccessor

      dependency_accessor :browser

      def initialize(options = {})
        @browser = options[:browser]
      end

      def show(*args)
        browser.visit component_path(*args)
      end

      private

      def component_path
        raise ConfigurationError, "You must define #{self.class.name}#component_path."
      end
    end
  end
end
