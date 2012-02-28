class Kookaburra::UIDriver
  require 'kookaburra/ui_driver/ui_component'

  class << self
    def ui_component(component_name, component_class)
      define_method(component_name) do
        component_class.new
      end
    end
  end
end
