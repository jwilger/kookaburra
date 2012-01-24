require 'helper'

describe Kookaburra::Assertion do
  let(:api)          { Class.new(Kookaburra::APIDriver).new({:app => nil}) }
  let(:given)        { Class.new(Kookaburra::GivenDriver).new({:api_driver => api, :test_data => nil}) }
  let(:ui_component) { Class.new(Kookaburra::UIDriver::UIComponent).new(:test_data => nil) }
  let(:ui) { ui_class.new }
  let(:ui_class) do
    Class.new(Kookaburra::UIDriver) do
      def positive_assertion
        assert true
      end

      def negative_assertion
        assert false
      end

      def negative_assertion_with_message
        assert false, "Hello, world!"
      end
    end
  end

  it 'should be included in Kookaburra::APIDriver' do
    assert_kind_of Kookaburra::Assertion, api
  end
  it 'should be included in Kookaburra::GivenDriver' do
    assert_kind_of Kookaburra::Assertion, given
  end
  it 'should be included in Kookaburra::UIDriver' do
    assert_kind_of Kookaburra::Assertion, ui
  end
  it 'should be included in Kookaburra::UIDriver::UIComponent' do
    assert_kind_of Kookaburra::Assertion, ui_component
  end

  it 'should be able to make a positive assertion' do
    ui.positive_assertion
  end
  
  it 'should be able to make a negative assertion' do
    assert_raises(Kookaburra::Assertion::Failure) do
      ui.negative_assertion
    end
  end
  
  it 'should be able to make a negative assertion with a custom failure message' do
    begin
      ui.negative_assertion_with_message
    rescue Kookaburra::Assertion::Failure => e
      assert_equal 'Hello, world!', e.message
    end
  end

  describe Kookaburra::Assertion::Failure do
    let(:base_path) { File.expand_path(File.join(File.dirname(__FILE__), *%w[.. .. lib kookaburra])) }

    it 'removes lines including assertion.rb from the top of its backtrace' do
      begin
        ui.negative_assertion
      rescue Kookaburra::Assertion::Failure => e
        assert e.backtrace.none? { |line| line.include?('lib/kookaburra/assertion.rb') },
          '"assertion.rb" should be cleaned from backtrace'
      end
    end
  end
  
end
