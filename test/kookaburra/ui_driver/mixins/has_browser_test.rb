require 'helper'

describe Kookaburra::UIDriver::HasBrowser do
  describe '#no_500_error!' do
    let(:klass) do
      Class.new do
        include Kookaburra::UIDriver::HasBrowser

        def run_test
          no_500_error!
        end
      end
    end

    let(:browser) do
      b = MiniTest::Mock.new
      def b.body; 'Hello'; end
      b
    end

    let(:obj) { klass.new(:browser => browser) }

    it 'raises Unexpected500 if the page title is "Internal Server Error"' do
      browser.expect(:all, [:not_empty],
                     [:css, 'head title', {:text => 'Internal Server Error'}])

      assert_raises Kookaburra::UIDriver::HasBrowser::Unexpected500 do
        obj.run_test
      end
    end

    it 'returns true if the page title is not "Internal Server Error"' do
      browser.expect(:all, [],
                     [:css, 'head title', {:text => 'Internal Server Error'}])
      assert_equal true, obj.run_test
    end
  end
end
