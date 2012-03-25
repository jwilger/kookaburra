require 'kookaburra/exceptions'
require 'kookaburra/mental_model'

describe Kookaburra::MentalModel do
  describe '#method_missing' do
    it 'returns a Collection' do
      subject.foo.should be_kind_of(Kookaburra::MentalModel::Collection)
    end

    it 'returns different Collections for different messages' do
      subject.foo.should_not === subject.bar
    end
  end

  describe Kookaburra::MentalModel::Collection do
    let(:collection) { Kookaburra::MentalModel::Collection.new('widgets') }

    describe '#slice' do
      it 'returns an array of items matching the specified keys' do
        collection[:foo] = 'foo'
        collection[:bar] = 'bar'
        collection[:baz] = 'baz'
        collection.slice(:foo, :baz).should == %w(foo baz)
      end
    end

    describe '#delete' do
      it 'deletes and returns the item matching the specified key' do
        collection[:baz] = 'baz'
        collection.delete(:baz).should == 'baz'
        lambda { collection[:baz] }.should raise_error(Kookaburra::UnknownKeyError)
      end

      it 'persists the deleted key/value pair to the #deleted subcollection' do
        collection[:baz] = 'baz'
        collection.delete(:baz)
        collection.deleted[:baz].should == 'baz'
      end

      it 'raises a Kookaburra::UnknownKeyError exception if trying to delete a missing key' do
        lambda { collection.delete(:snerf) }.should \
          raise_error(Kookaburra::UnknownKeyError, "Can't find mental_model.widgets[:snerf]. Did you forget to set it?")
      end
    end

    describe '#delete_if' do
      before(:each) do
        collection[:foo] = 'foo'
        collection[:bar] = 'spoon'
        collection[:baz] = 'baz'
      end

      it 'deletes all members of collection for whom given block evaluates to false' do
        collection.delete_if { |k,v| k.to_s != v }
        collection.keys.should =~ [:foo, :baz]
      end

      it 'adds deleted members of collection to #deleted subcollection' do
        collection.delete_if { |k,v| k.to_s != v }
        collection.deleted.keys.should == [:bar]
      end

      it 'returns hash of items not deleted' do
        collection.delete_if { |k,v| k.to_s != v }.should == { :foo => 'foo', :baz => 'baz' }
      end
    end

    describe '#deleted' do
      it 'generates a new subcollection if none exists' do
        initialized_collection = collection
        Kookaburra::MentalModel::Collection.should_receive(:new).with("deleted")
        initialized_collection.deleted
      end

      it 'returns the deleted subcollection if already initialized' do
        deleted_collection = collection.deleted
        collection.deleted.should === deleted_collection
      end
    end

    it 'raises a Kookaburra::UnknownKeyError exception for #[] with a missing key' do
      lambda { collection[:foo] }.should \
        raise_error(Kookaburra::UnknownKeyError, "Can't find mental_model.widgets[:foo]. Did you forget to set it?")
    end
  end
end
