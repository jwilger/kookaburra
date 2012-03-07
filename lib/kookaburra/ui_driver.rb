require 'kookaburra/dependency_accessor'
require 'kookaburra/ui_driver/ui_component'

class Kookaburra
  class UIDriver
    class << self
      def ui_component(component_name, component_class)
        define_method(component_name) do
          component_class.new(:browser => browser, :server_error_detection => @server_error_detection)
        end
      end
    end

    def initialize(options = {})
      @browser = options[:browser]
      @test_data = options[:test_data]
      @server_error_detection = options[:server_error_detection]
    end

    private

    extend DependencyAccessor
    dependency_accessor :browser, :test_data
  end
end
