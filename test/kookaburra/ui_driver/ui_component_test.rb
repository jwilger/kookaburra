require 'helper'
require 'minitest/mock'

describe Kookaburra::UIDriver::UIComponent do
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
