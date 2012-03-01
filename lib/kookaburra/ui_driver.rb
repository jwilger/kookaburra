require 'active_support/core_ext/string'

class Kookaburra
  class UIDriver
    class << self
      def ui_component(component_name, component_class)
        define_method(component_name) do
          component_class.new(:browser => browser)
        end
      end
    end

    def initialize(options = {})
      @browser = options[:browser]
    end

    private

    def browser
      @browser or raise "No browser object was set on %s initialization." \
        % [self.class.name, 'an Anonymous Class!!!'].reject(&:blank?).first
    end
  end
end
