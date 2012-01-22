require 'helper'

describe Kookaburra::UIDriver do
  describe '#navigate_to' do
    it 'raises a UIComponentNotFound if the specified UIComponent is not registered' do
      ui = Kookaburra::UIDriver.new
      assert_raises Kookaburra::UIDriver::UIComponentNotFound do
        ui.navigate_to(:nonexistent_component)
      end
    end

    Foo = Class.new do
      @@last_instance = nil

      def self.was_shown
        @@last_instance.was_shown
      end

      def self.params
        @@last_instance.params
      end

      def initialize(options)
        @@last_instance = self
      end

      def show!(params = {})
        @was_shown = true
        @params = params
      end
      attr_reader :was_shown, :params
    end

    let(:ui) { ui_class.new }
    let(:ui_class) do
      Class.new(Kookaburra::UIDriver) do
        def browser; end
        def test_data; end

        ui_component :foo
      end
    end

    it 'delegates to the UIComponent#show! method' do
      ui.navigate_to :foo
      assert Foo.was_shown, "#show! was never called on the Foo component"
    end

    it 'passed any additional options to the UIComponent#show! method' do
      ui.navigate_to :foo, :bar => :baz
      assert_equal({:bar => :baz}, Foo.params)
    end
  end
end
