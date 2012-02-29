require 'kookaburra/ui_driver'

describe Kookaburra::UIDriver do
  describe '.ui_component' do
    it 'adds an accessor method for the named component that defaults to an instance of the specified class' do
      foo_component_class = Class.new

      ui_driver_class = Class.new(Kookaburra::UIDriver) do
        ui_component :foo, foo_component_class
      end

      ui = ui_driver_class.new
      ui.foo.should be_kind_of(foo_component_class)
    end
  end
end
