require 'kookaburra/test_data'

describe Kookaburra::TestData do
  describe '#method_missing' do
    it 'returns a Collection' do
      subject.foo.should be_kind_of(Kookaburra::TestData::Collection)
    end

    it 'returns different Collections for different messages' do
      subject.foo.should_not === subject.bar
    end
  end

  describe Kookaburra::TestData::Collection do
    let(:collection) { Kookaburra::TestData::Collection.new('widgets') }

    it 'is somewhat hash-like' do
      collection[:foo] = :foo
      collection[:foo].should == :foo
    end

    it 'raises a Kookaburra::TestData::NoSuchKey exception for #[] with a missing key' do
      lambda { collection[:foo] }.should \
        raise_error(Kookaburra::TestData::UnknownKeyError, "Can't find test_data.widgets[:foo]. Did you forget to set it?")
    end
  end
end
