require 'kookaburra/dependency_accessor'

class Kookaburra
  class UIDriver
    extend DependencyAccessor

    dependency_accessor :browser, :test_data

    class << self
      def ui_component(component_name, component_class)
        define_method(component_name) do
          component_class.new(:browser => browser)
        end
      end
    end

    def initialize(options = {})
      @browser = options[:browser]
      @test_data = options[:test_data]
    end
  end
end
