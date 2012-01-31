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

  describe '#show' do
    let(:browser) { MiniTest::Mock.new }
    let(:component) do
      c = Kookaburra::UIDriver::UIComponent.new(:browser => browser)
      def c.no_500_error!; true; end
      c
    end

    it 'raises a NoMethodError if #component_path is not defined' do
      assert_raises_with_message(NoMethodError, /set component_path/)  do
        component.show
      end
    end

    describe "when the component is not already visible" do
      before(:each) do
        def component.visible?; false; end
      end

      it 'visits the path returned by #component_path' do
        def component.component_path; '/my/path'; end
        browser.expect(:visit, nil, ['/my/path'])
        component.show
      end

      it 'passes any arguments through to #component_path' do
        def browser.visit(*args); nil; end

        def component.component_path(*args)
          unless args == %w[one two three]
            raise "Expected #component_path('one', 'two', 'three') but called with #{args.inspect}"
          end
        end

        component.show('one', 'two', 'three')
      end
    end

    describe "when the component is already visible" do
      it 'does not visit the component path' do
        def component.component_path; '/my/path'; end
        def component.visible?; true; end

        def browser.visit(*args); raise "Shouldn't get called"; end
        component.show
      end
    end
  end
end
