require 'kookaburra/ui_driver'

describe Kookaburra::UIDriver do
  describe '.ui_component' do
    it 'adds an accessor method for the named component that defaults to an instance of the specified class' do
      foo_component_class = Class.new do
        def initialize(options = {}); end
      end

      ui_driver_class = Class.new(Kookaburra::UIDriver) do
        ui_component :foo, foo_component_class
      end

      ui = ui_driver_class.new(:browser => :a_browser)
      ui.foo.should be_kind_of(foo_component_class)
    end
  end

  it_behaves_like :browser_injection do
    let(:subject_class) { Kookaburra::UIDriver }
  end
end
