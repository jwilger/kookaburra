class Kookaburra
  class UIDriver
    class UIComponent
      def initialize(options = {})
        @browser = options[:browser]
      end

      def show(*args)
        browser.visit component_path(*args)
      end

      private

      def browser
        @browser or raise "No browser object was set on #{class_name} initialization."
      end

      def component_path
        raise ConfigurationError, "You must define #{class_name}#component_path."
      end

      def class_name
        self.class.name
      end
    end
  end
end
