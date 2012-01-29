require 'helper'
require 'minitest/mock'

describe Kookaburra::UIDriver::UIComponent do
  it 'can have nested UIComponents' do
    InnerComponentA = Class.new(Kookaburra::UIDriver::UIComponent) do
      def visible?
        true
      end
    end

    InnerComponentB = Class.new(Kookaburra::UIDriver::UIComponent) do
      def visible?
        false
      end
    end

    OuterComponent = Class.new(Kookaburra::UIDriver::UIComponent) do
      ui_component :inner_component_a
      ui_component :inner_component_b
    end

    component = OuterComponent.new(:browser => Object.new)
    assert_equal true, component.has_inner_component_a?
    assert_equal false, component.has_inner_component_b?
  end

  let(:component_class) do
    Class.new(Kookaburra::UIDriver::UIComponent) do
      component_locator '#my_component'
      public :count
    end
  end

  describe '#count' do
    it 'returns the number of elements found within the component' do
      browser = Object.new.tap do |b|
        def b.within(*args)
          @context_set = true
          yield self
        end

        def b.all(*args)
          return unless @context_set
          Array.new(3)
        end
      end
      component = component_class.new(:browser => browser)
      assert_equal 3, component.count('.element')
    end
  end
end
