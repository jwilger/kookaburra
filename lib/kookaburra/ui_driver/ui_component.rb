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
        @browser or raise "No browser object was set on #{self.class.name} initialization."
      end

      def component_path
        raise ConfigurationError, "You must define #{self.class.name}#component_path."
      end
    end
  end
end
