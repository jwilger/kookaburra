require 'helper'

describe Kookaburra::TestData do
  describe '.set_default' do
    it 'stores data that can be used as defaults for tests' do
      Kookaburra::TestData.set_default(:foo, 'bar')
      td = Kookaburra::TestData.new
      assert_equal 'bar', Kookaburra::TestData.default(:foo)
    end
  end

  describe '#default' do
    it 'does not allow default to change between instances' do
      Kookaburra::TestData.set_default(:foo, 'bar' => 'baz')
      td1 = Kookaburra::TestData.new
      td1.default(:foo)['bar'] = 'spam'
      td2 = Kookaburra::TestData.new
      assert_equal 'baz', td2.default(:foo)['bar']
    end

    it 'raises an IndexError if the requested default has not been defined' do
      td = Kookaburra::TestData.new
      assert_raises IndexError do
        td.default(:foobar)
      end
    end
  end
end
